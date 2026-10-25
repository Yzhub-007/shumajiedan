package com.repairhub.dispatch.service;

import com.repairhub.common.config.OrderProperties;
import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.common.util.GeoUtils;
import com.repairhub.common.util.JsonUtils;
import com.repairhub.dispatch.entity.DispatchRecord;
import com.repairhub.dispatch.entity.DispatchType;
import com.repairhub.dispatch.repository.DispatchRecordRepository;
import com.repairhub.notify.service.NotificationService;
import com.repairhub.order.entity.DeviceCategory;
import com.repairhub.order.entity.Order;
import com.repairhub.order.enums.Urgency;
import com.repairhub.order.event.OrderCreatedEvent;
import com.repairhub.order.repository.DeviceCategoryRepository;
import com.repairhub.order.repository.OrderRepository;
import com.repairhub.user.entity.EngineerProfile;
import com.repairhub.user.entity.VerifyStatus;
import com.repairhub.user.repository.EngineerProfileRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 派单引擎（计划书 3.1.3）：
 * V0 发单后查询半径内在线匹配工程师 → 推送 + 记录；
 * 已支持技能匹配、重复推送去重、超时扩大半径重派，并为后台人工指派提供附近候选人。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DispatchService {

    private final EngineerLocationService locationService;
    private final EngineerProfileRepository engineerProfileRepository;
    private final DispatchRecordRepository dispatchRecordRepository;
    private final DeviceCategoryRepository deviceCategoryRepository;
    private final OrderRepository orderRepository;
    private final NotificationService notificationService;
    private final OrderProperties orderProperties;

    /** 新工单派单入口（监听 order 模块事件，避免模块间直接依赖 Service） */
    @EventListener
    public void onOrderCreated(OrderCreatedEvent event) {
        orderRepository.findById(event.orderId()).ifPresent(this::dispatchNewOrder);
    }

    public void dispatchNewOrder(Order order) {
        dispatch(order, 1.0, false);
    }

    /** 超时重派：半径翻倍（计划书 2.2：PENDING 超时扩大派单半径） */
    public void redispatch(Order order) {
        dispatch(order, 2.0, true);
    }

    private void dispatch(Order order, double radiusMultiplier, boolean isRedispatch) {
        double radiusKm = orderProperties.getDispatchRadiusKm()
                * urgencyMultiplier(order.getUrgency()) * radiusMultiplier;
        DeviceCategory category = deviceCategoryRepository.findByIdOrNull(order.getDeviceCategoryId());

        Set<Long> alreadyPushed = dispatchRecordRepository
                .findByOrderIdAndType(order.getId(), DispatchType.PUSH).stream()
                .map(DispatchRecord::getEngineerId)
                .collect(Collectors.toSet());

        Map<Long, EngineerProfile> approved = engineerProfileRepository
                .findByVerifyStatus(VerifyStatus.APPROVED).stream()
                .collect(Collectors.toMap(EngineerProfile::getUserId, p -> p));

        List<EngineerLocationService.NearbyEngineer> targets =
                locationService.searchNearby(order.getLng(), order.getLat(), radiusKm).stream()
                        .filter(c -> approved.containsKey(c.engineerId()))
                        .filter(c -> !alreadyPushed.contains(c.engineerId()))
                        .filter(c -> skillMatch(approved.get(c.engineerId()), category))
                        .sorted(Comparator.comparingInt(EngineerLocationService.NearbyEngineer::distanceM))
                        .toList();

        for (EngineerLocationService.NearbyEngineer candidate : targets) {
            saveRecord(order.getId(), candidate.engineerId(), DispatchType.PUSH, candidate.distanceM());
            String prefix = isRedispatch ? "【加急】" : "";
            notificationService.send(candidate.engineerId(), "NEW_ORDER", prefix + "有新的维修工单",
                    "附近有新工单，距离约 " + Math.round(candidate.distanceM() / 1000.0 * 10) / 10.0
                            + " km，请尽快抢单",
                    Map.of("orderId", order.getId()));
        }
        if (targets.isEmpty()) {
            log.warn("工单 {} 半径 {}km 内无可推送工程师（redispatch={}）", order.getId(), radiusKm, isRedispatch);
        }
    }

    /** 客户发单前查询附近在线工程师数（API: /api/orders/{id}/nearby-count） */
    public long nearbyEngineerCount(double lng, double lat) {
        return locationService.countNearby(lng, lat, orderProperties.getDispatchRadiusKm());
    }

    /** 技能匹配：skill_tags 命中设备类型名；未填技能的工程师默认可派（兼顾双边冷启动） */
    public boolean skillMatch(EngineerProfile profile, DeviceCategory category) {
        if (!orderProperties.isSmartDispatchSkillMatch() || category == null) {
            return true;
        }
        List<String> tags = JsonUtils.readStringArray(profile.getSkillTags());
        if (tags.isEmpty()) {
            return true;
        }
        return tags.stream().anyMatch(t -> t.equalsIgnoreCase(category.getName()));
    }

    /** 后台人工指派的附近候选人（计划书 3.3.1：指派时选择附近在线工程师） */
    public List<NearbyEngineerView> listNearbyForOrder(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BizException(ErrorCode.ORDER_NOT_FOUND));
        double radiusKm = orderProperties.getDispatchRadiusKm() * urgencyMultiplier(order.getUrgency()) * 2;
        Map<Long, EngineerProfile> approved = engineerProfileRepository
                .findByVerifyStatus(VerifyStatus.APPROVED).stream()
                .collect(Collectors.toMap(EngineerProfile::getUserId, p -> p));
        return locationService.searchNearby(order.getLng(), order.getLat(), radiusKm).stream()
                .filter(c -> approved.containsKey(c.engineerId()))
                .sorted(Comparator.comparingInt(EngineerLocationService.NearbyEngineer::distanceM))
                .map(c -> {
                    EngineerProfile p = approved.get(c.engineerId());
                    return new NearbyEngineerView(p.getUserId(), p.getRealName(), c.distanceM(),
                            p.getRatingAvg(), p.getOrderCount(),
                            Boolean.TRUE.equals(p.getOnlineStatus()));
                })
                .toList();
    }

    /** 后台指派（API: /admin/orders/{id}/assign） */
    public void recordAssign(Long orderId, Long engineerId) {
        EngineerProfile profile = engineerProfileRepository.findById(engineerId)
                .orElseThrow(() -> new BizException(ErrorCode.NOT_FOUND, "工程师不存在"));
        if (profile.getVerifyStatus() != VerifyStatus.APPROVED) {
            throw new BizException(ErrorCode.ENGINEER_NOT_APPROVED);
        }
        int distanceM = (int) Math.round(orderRepository.findById(orderId)
                .map(o -> GeoUtils.distanceTo(o, profile))
                .orElse(0D));
        saveRecord(orderId, engineerId, DispatchType.ASSIGN, distanceM);
        notificationService.send(engineerId, "ORDER_ASSIGNED", "平台已向您指派工单",
                "请在 30 分钟内确认出发，超时工单将被释放", Map.of("orderId", orderId));
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

    public record NearbyEngineerView(Long userId, String realName, Integer distanceM,
                                     BigDecimal ratingAvg, Integer orderCount, boolean onlineStatus) {
    }
}
