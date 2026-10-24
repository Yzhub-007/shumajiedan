package com.repairhub.dispatch.service;

import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.dispatch.entity.DispatchRecord;
import com.repairhub.dispatch.entity.DispatchType;
import com.repairhub.dispatch.repository.DispatchRecordRepository;
import com.repairhub.notify.service.NotificationService;
import com.repairhub.order.entity.Order;
import com.repairhub.order.enums.OrderStatus;
import com.repairhub.order.entity.OrderStatusLog;
import com.repairhub.order.repository.OrderRepository;
import com.repairhub.order.repository.OrderStatusLogRepository;
import com.repairhub.user.entity.EngineerProfile;
import com.repairhub.user.entity.VerifyStatus;
import com.repairhub.user.repository.EngineerProfileRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Map;

/**
 * 抢单（计划书 5.1.2）：Redis 分布式锁 + 数据库条件更新（乐观锁语义），保证一单只被一人抢到。
 * 验收标准：并发 100 人抢同一单，仅 1 人成功。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class GrabService {

    private static final Duration LOCK_TTL = Duration.ofSeconds(10);

    private final StringRedisTemplate redis;
    private final OrderRepository orderRepository;
    private final OrderStatusLogRepository statusLogRepository;
    private final DispatchRecordRepository dispatchRecordRepository;
    private final EngineerProfileRepository engineerProfileRepository;
    private final NotificationService notificationService;

    @Transactional
    public void grab(Long orderId, Long engineerId) {
        checkEngineerApproved(engineerId);

        // 1. Redis 分布式锁（同一工单同时只放一个请求进来）
        String lockKey = "lock:order:" + orderId;
        Boolean locked = redis.opsForValue().setIfAbsent(lockKey, String.valueOf(engineerId), LOCK_TTL);
        if (!Boolean.TRUE.equals(locked)) {
            throw new BizException(ErrorCode.GRAB_CONFLICT);
        }
        try {
            // 2. 条件更新：仅当仍为 PENDING 时接单成功
            int updated = orderRepository.grab(orderId, engineerId,
                    OrderStatus.ACCEPTED, OrderStatus.PENDING, LocalDateTime.now());
            if (updated == 0) {
                throw new BizException(ErrorCode.GRAB_CONFLICT);
            }

            Order order = orderRepository.findById(orderId).orElseThrow();

            // 3. 流水 + 派单记录 + 通知
            saveStatusLog(orderId, engineerId);
            saveGrabRecord(orderId, engineerId);
            notificationService.send(order.getCustomerId(), "ORDER_ACCEPTED", "工单已被接单",
                    "工程师已接单，将尽快与您联系", Map.of("orderId", orderId));
        } finally {
            redis.delete(lockKey);
        }
    }

    private void checkEngineerApproved(Long engineerId) {
        EngineerProfile profile = engineerProfileRepository.findById(engineerId)
                .orElseThrow(() -> new BizException(ErrorCode.FORBIDDEN, "请先完成工程师资质认证"));
        if (profile.getVerifyStatus() != VerifyStatus.APPROVED) {
            throw new BizException(ErrorCode.ENGINEER_NOT_APPROVED);
        }
    }

    private void saveStatusLog(Long orderId, Long operatorId) {
        OrderStatusLog logEntry = new OrderStatusLog();
        logEntry.setOrderId(orderId);
        logEntry.setFromStatus(OrderStatus.PENDING);
        logEntry.setToStatus(OrderStatus.ACCEPTED);
        logEntry.setOperatorId(operatorId);
        logEntry.setOperatorRole("ENGINEER");
        logEntry.setRemark("工程师抢单");
        statusLogRepository.save(logEntry);
    }

    private void saveGrabRecord(Long orderId, Long engineerId) {
        DispatchRecord record = new DispatchRecord();
        record.setOrderId(orderId);
        record.setEngineerId(engineerId);
        record.setType(DispatchType.GRAB);
        dispatchRecordRepository.save(record);
    }
}
