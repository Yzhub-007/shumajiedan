package com.repairhub.dispatch.service;

import com.repairhub.common.config.OrderProperties;
import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.dispatch.entity.DispatchRecord;
import com.repairhub.dispatch.entity.DispatchType;
import com.repairhub.dispatch.repository.DispatchRecordRepository;
import com.repairhub.notify.service.NotificationService;
import com.repairhub.order.entity.Order;
import com.repairhub.order.enums.Urgency;
import com.repairhub.order.event.OrderCreatedEvent;
import com.repairhub.order.repository.OrderRepository;
import com.repairhub.user.entity.EngineerProfile;
import com.repairhub.user.entity.VerifyStatus;
import com.repairhub.user.repository.EngineerProfileRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 派单引擎 V0（计划书 3.1.3）：发单事件 → 半径内在线工程师 → 推送 + 记录。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DispatchService {

    private final EngineerLocationService locationService;
    private final EngineerProfileRepository engineerProfileRepository;
    private final DispatchRecordRepository dispatchRecordRepository;
    private final OrderRepository orderRepository;
    private final NotificationService notificationService;
    private final OrderProperties orderProperties;

    /** 新工单派单入口（监听 order 模块事件，避免模块间直接依赖 Service） */
    @org.springframework.context.event.EventListener
    public void onOrderCreated(OrderCreatedEvent event) {
        orderRepository.findById(event.orderId()).ifPresent(this::dispatchNewOrder);
    }

    public void dispatchNewOrder(Order order) {
        double radiusKm = orderProperties.getDispatchRadiusKm() * urgencyMultiplier(order.getUrgency());
        List<EngineerLocationService.NearbyEngineer> nearby =
                locationService.searchNearby(order.getLng(), order.getLat(), radiusKm);

        // TODO(3.1.3) V1.1 智能派单：技能匹配(skill_tags ∩ device_category) + 评分 + 当前负载加权打分
        Set<Long> approvedIds = engineerProfileRepository.findByVerifyStatus(VerifyStatus.APPROVED).stream()
                .map(EngineerProfile::getUserId)
                .collect(Collectors.toSet());

        int pushed = 0;
        for (EngineerLocationService.NearbyEngineer candidate : nearby) {
            if (!approvedIds.contains(candidate.engineerId())) {
                continue;
            }
            saveRecord(order.getId(), candidate.engineerId(), DispatchType.PUSH, candidate.distanceM());
            notificationService.send(candidate.engineerId(), "NEW_ORDER", "有新的维修工单",
                    "附近有新工单，距离约 " + Math.round(candidate.distanceM() / 1000.0 * 10) / 10.0 + " km，请尽快抢单",
                    Map.of("orderId", order.getId()));
            pushed++;
        }
        if (pushed == 0) {
            log.warn("工单 {} 半径 {}km 内无可用工程师", order.getId(), radiusKm);
            // TODO(3.1.12) PENDING 超时无人接单 → 扩大半径 / 通知后台人工介入
        }
    }

    /** 客户发单前查询附近在线工程师数（API: /api/orders/{id}/nearby-count） */
    public long nearbyEngineerCount(double lng, double lat) {
        return locationService.countNearby(lng, lat, orderProperties.getDispatchRadiusKm());
    }

    /** 后台指派（API: /admin/orders/{id}/assign） */
    public void recordAssign(Long orderId, Long engineerId) {
        EngineerProfile profile = engineerProfileRepository.findById(engineerId)
                .orElseThrow(() -> new BizException(ErrorCode.NOT_FOUND, "工程师不存在"));
        if (profile.getVerifyStatus() != VerifyStatus.APPROVED) {
            throw new BizException(ErrorCode.ENGINEER_NOT_APPROVED);
        }
        int distanceM = (int) Math.round(orderRepository.findById(orderId)
                .map(o -> distanceToEngineer(o, profile))
                .orElse(0D));
        saveRecord(orderId, engineerId, DispatchType.ASSIGN, distanceM);
        notificationService.send(engineerId, "ORDER_ASSIGNED", "平台已向您指派工单",
                "请在 30 分钟内确认出发，超时工单将被释放", Map.of("orderId", orderId));
    }

    private double distanceToEngineer(Order order, EngineerProfile profile) {
        return com.repairhub.common.util.GeoUtils.distanceMeters(
                order.getLng(), order.getLat(), profile.getLastLng(), profile.getLastLat());
    }

    private double urgencyMultiplier(Urgency urgency) {
        return switch (urgency) {
            case CRITICAL -> 2.0;
            case URGENT -> 1.5;
            case NORMAL -> 1.0;
        };
    }

    private void saveRecord(Long orderId, Long engineerId, DispatchType type, Integer distanceM) {
        DispatchRecord record = new DispatchRecord();
        record.setOrderId(orderId);
        record.setEngineerId(engineerId);
        record.setType(type);
        record.setDistanceM(distanceM);
        dispatchRecordRepository.save(record);
    }
}
