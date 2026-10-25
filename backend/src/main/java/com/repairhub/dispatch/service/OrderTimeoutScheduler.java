package com.repairhub.dispatch.service;

import com.repairhub.common.config.OrderProperties;
import com.repairhub.common.exception.BizException;
import com.repairhub.notify.service.NotificationService;
import com.repairhub.order.entity.Order;
import com.repairhub.order.enums.OrderStatus;
import com.repairhub.order.event.OrderStatusChangedEvent;
import com.repairhub.order.repository.OrderRepository;
import com.repairhub.order.service.OrderActionService;
import com.repairhub.order.state.OrderAction;
import com.repairhub.user.entity.UserRole;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 工单超时调度（计划书 2.2 超时规则 / 任务 3.1.12）。
 *
 * 实现：Redis ZSet 延迟扫描（score=到期时间戳），不依赖 RabbitMQ 延迟插件，
 * 后续切 MQ 时仅需替换 schedule/poll 两个方法。
 *
 * 规则：
 * - PENDING 超过 pendingTimeoutMinutes 无人接单 → 扩大半径重派
 * - ACCEPTED 超过 departRemindMinutes 未出发 → 提醒工程师
 * - ACCEPTED 超过 departReleaseMinutes 未出发 → 自动释放回单池
 * - PENDING_CONFIRM 超过 autoConfirmHours 未验收 → 自动验收通过
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class OrderTimeoutScheduler {

    private static final String ZSET_KEY = "order:timeout";

    static final String PHASE_PENDING_REDISPATCH = "PENDING_REDISPATCH";
    static final String PHASE_DEPART_REMIND = "DEPART_REMIND";
    static final String PHASE_DEPART_RELEASE = "DEPART_RELEASE";
    static final String PHASE_AUTO_CONFIRM = "AUTO_CONFIRM";

    private static final List<String> ALL_PHASES = List.of(
            PHASE_PENDING_REDISPATCH, PHASE_DEPART_REMIND, PHASE_DEPART_RELEASE, PHASE_AUTO_CONFIRM);

    private final StringRedisTemplate redis;
    private final OrderRepository orderRepository;
    private final OrderActionService orderActionService;
    private final DispatchService dispatchService;
    private final NotificationService notificationService;
    private final OrderProperties orderProperties;

    /** 状态每次变更时重排该工单的超时计划 */
    @EventListener
    public void onOrderStatusChanged(OrderStatusChangedEvent event) {
        try {
            reschedule(event.orderId(), event.to(), event.action());
        } catch (Exception e) {
            // 调度失败不影响主流程
            log.warn("超时计划编排失败 orderId={}", event.orderId(), e);
        }
    }

    private void reschedule(Long orderId, OrderStatus to, OrderAction action) {
        // 先清掉该工单全部旧计划，再按新状态排新计划（幂等）
        for (String phase : ALL_PHASES) {
            redis.opsForZSet().remove(ZSET_KEY, member(orderId, phase));
        }
        long now = System.currentTimeMillis();
        switch (to) {
            case PENDING -> schedule(orderId, PHASE_PENDING_REDISPATCH,
                    now + Duration.ofMinutes(orderProperties.getPendingTimeoutMinutes()).toMillis());
            case ACCEPTED -> {
                // 取消动作到达 ACCEPTED 不存在；RELEASE 回 PENDING 上面分支处理
                schedule(orderId, PHASE_DEPART_REMIND,
                        now + Duration.ofMinutes(orderProperties.getDepartRemindMinutes()).toMillis());
                schedule(orderId, PHASE_DEPART_RELEASE,
                        now + Duration.ofMinutes(orderProperties.getDepartReleaseMinutes()).toMillis());
            }
            case PENDING_CONFIRM -> schedule(orderId, PHASE_AUTO_CONFIRM,
                    now + Duration.ofHours(orderProperties.getAutoConfirmHours()).toMillis());
            default -> {
                // 终态/中间态无需计划
            }
        }
    }

    private void schedule(Long orderId, String phase, long deadlineMillis) {
        redis.opsForZSet().add(ZSET_KEY, member(orderId, phase), deadlineMillis);
    }

    /** 每 30 秒扫描到期任务；先原子移除再处理，避免多实例重复执行 */
    @Scheduled(fixedDelay = 30_000)
    public void poll() {
        Set<String> due = redis.opsForZSet().rangeByScore(ZSET_KEY, 0, System.currentTimeMillis(), 0, 100);
        if (due == null || due.isEmpty()) {
            return;
        }
        for (String entry : due) {
            Long removed = redis.opsForZSet().remove(ZSET_KEY, entry);
            if (removed != null && removed == 1) {
                handle(entry);
            }
        }
    }

    private void handle(String entry) {
        int idx = entry.lastIndexOf(':');
        if (idx <= 0) {
            return;
        }
        long orderId = Long.parseLong(entry.substring(0, idx));
        String phase = entry.substring(idx + 1);
        Order order = orderRepository.findById(orderId).orElse(null);
        if (order == null) {
            return;
        }
        switch (phase) {
            case PHASE_PENDING_REDISPATCH -> {
                if (order.getStatus() == OrderStatus.PENDING) {
                    log.info("工单 {} 待接单超时，扩大半径重派", orderId);
                    dispatchService.redispatch(order);
                    notificationService.send(order.getCustomerId(), "ORDER_TIMEOUT", "正在加急匹配工程师",
                            "暂时无人接单，已为您扩大匹配范围并通知更多工程师", Map.of("orderId", orderId));
                }
            }
            case PHASE_DEPART_REMIND -> {
                if (order.getStatus() == OrderStatus.ACCEPTED && order.getEngineerId() != null) {
                    notificationService.send(order.getEngineerId(), "DEPART_REMIND", "请尽快出发",
                            "已接单超过 " + orderProperties.getDepartRemindMinutes() + " 分钟仍未出发，超时工单将被释放",
                            Map.of("orderId", orderId));
                }
            }
            case PHASE_DEPART_RELEASE -> {
                if (order.getStatus() == OrderStatus.ACCEPTED) {
                    log.info("工单 {} 已接单超时未出发，自动释放回单池", orderId);
                    orderActionService.apply(orderId, OrderAction.RELEASE, null, UserRole.SYSTEM,
                            "超时未出发，系统自动释放回单池");
                }
            }
            case PHASE_AUTO_CONFIRM -> {
                if (order.getStatus() == OrderStatus.PENDING_CONFIRM) {
                    log.info("工单 {} 超时未验收，自动验收通过", orderId);
                    try {
                        orderActionService.apply(orderId, OrderAction.CONFIRM_FINISH, null, UserRole.SYSTEM,
                                "超过 " + orderProperties.getAutoConfirmHours() + " 小时未验收，系统自动通过");
                    } catch (BizException e) {
                        log.warn("自动验收失败 orderId={}", orderId, e);
                    }
                }
            }
            default -> {
            }
        }
    }

    private String member(Long orderId, String phase) {
        return orderId + ":" + phase;
    }
}
