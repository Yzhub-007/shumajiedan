package com.repairhub.order.service;

import com.repairhub.common.config.OrderProperties;
import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.common.response.PageResult;
import com.repairhub.common.util.GeoUtils;
import com.repairhub.common.util.JsonUtils;
import com.repairhub.order.dto.EngineerStatsResponse;
import com.repairhub.order.dto.OrderResponse;
import com.repairhub.order.dto.PoolOrderResponse;
import com.repairhub.order.entity.DeviceCategory;
import com.repairhub.order.entity.Order;
import com.repairhub.order.entity.RepairReport;
import com.repairhub.order.enums.OrderStatus;
import com.repairhub.order.repository.DeviceCategoryRepository;
import com.repairhub.order.repository.OrderRepository;
import com.repairhub.order.repository.RepairReportRepository;
import com.repairhub.order.state.OrderAction;
import com.repairhub.user.entity.EngineerProfile;
import com.repairhub.user.entity.User;
import com.repairhub.user.entity.UserRole;
import com.repairhub.user.repository.EngineerProfileRepository;
import com.repairhub.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

/**
 * 工程师端工单：工单池、上门链路动作、完工提交、我的工单（计划书 3.1.3~3.1.7）。
 */
@Service
@RequiredArgsConstructor
public class EngineerOrderService {

    private final OrderRepository orderRepository;
    private final DeviceCategoryRepository deviceCategoryRepository;
    private final EngineerProfileRepository engineerProfileRepository;
    private final UserRepository userRepository;
    private final RepairReportRepository reportRepository;
    private final OrderActionService orderActionService;
    private final OrderProperties orderProperties;

    /** 可抢工单池：PENDING 工单按创建时间倒序，附工程师当前距离 */
    @Transactional(readOnly = true)
    public List<PoolOrderResponse> pool(Long engineerId, int limit) {
        EngineerProfile profile = engineerProfileRepository.findById(engineerId).orElse(null);
        Page<Order> page = orderRepository.findByStatus(OrderStatus.PENDING,
                PageRequest.of(0, Math.min(limit, 50), Sort.by(Sort.Direction.DESC, "createdAt")));
        return page.getContent().stream()
                .map(order -> toPoolItem(order, profile))
                .toList();
    }

    @Transactional(readOnly = true)
    public PageResult<OrderResponse> myOrders(Long engineerId, String status, int page, int size) {
        Pageable pageable = PageRequest.of(Math.max(page - 1, 0), Math.min(size, 50),
                Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Order> result = (status == null || status.isBlank())
                ? orderRepository.findByEngineerId(engineerId, pageable)
                : orderRepository.findByEngineerIdAndStatus(engineerId, parseStatus(status), pageable);
        return PageResult.of(result, this::toSimpleResponse);
    }

    @Transactional
    public void depart(Long orderId, Long engineerId) {
        Order order = loadOwn(orderId, engineerId);
        orderActionService.apply(orderId, OrderAction.DEPART, engineerId, UserRole.ENGINEER, "出发上门");
    }

    /** 到达签到：GPS 距离校验 ≤ 配置半径（计划书 3.1.5） */
    @Transactional
    public void arrive(Long orderId, Long engineerId, Double lng, Double lat) {
        Order order = loadOwn(orderId, engineerId);
        if (order.getLng() != null && order.getLat() != null
                && (order.getLng() != 0D || order.getLat() != 0D)
                && lng != null && lat != null) {
            double distance = GeoUtils.distanceMeters(order.getLng(), order.getLat(), lng, lat);
            if (distance > orderProperties.getArriveCheckRadiusM()) {
                throw new BizException(ErrorCode.ARRIVE_TOO_FAR,
                        "距离服务地址还有 " + Math.round(distance) + " 米，无法签到");
            }
        }
        orderActionService.apply(orderId, OrderAction.ARRIVE, engineerId, UserRole.ENGINEER, "到达签到");
    }

    @Transactional
    public void startRepair(Long orderId, Long engineerId) {
        loadOwn(orderId, engineerId);
        orderActionService.apply(orderId, OrderAction.START_REPAIR, engineerId, UserRole.ENGINEER, "开始维修");
    }

    /** 完工提交：维修报告 + 现场照片（计划书 3.1.7） */
    @Transactional
    public void finish(Long orderId, Long engineerId,
                       String diagnosis, String solution,
                       List<String> beforePhotos, List<String> afterPhotos, List<String> partsReplaced) {
        Order order = loadOwn(orderId, engineerId);
        RepairReport report = new RepairReport();
        report.setOrderId(orderId);
        report.setDiagnosis(diagnosis);
        report.setSolution(solution);
        report.setBeforePhotos(JsonUtils.write(beforePhotos));
        report.setAfterPhotos(JsonUtils.write(afterPhotos));
        report.setPartsReplaced(JsonUtils.write(partsReplaced));
        reportRepository.save(report);

        orderActionService.apply(orderId, OrderAction.FINISH, engineerId, UserRole.ENGINEER, "完工提交");

        engineerProfileRepository.findById(engineerId).ifPresent(profile -> {
            profile.setOrderCount((int) orderRepository.countByEngineerId(engineerId));
            engineerProfileRepository.save(profile);
        });
    }

    /** 无法修复关闭 */
    @Transactional
    public void closeUnresolved(Long orderId, Long engineerId, String reason) {
        loadOwn(orderId, engineerId);
        orderActionService.apply(orderId, OrderAction.CLOSE_UNRESOLVED, engineerId, UserRole.ENGINEER, reason);
    }

    /** 工程师统计：接单数/完成数/累计收入/评分（展示用，计划书 3.1.13） */
    @Transactional(readOnly = true)
    public EngineerStatsResponse stats(Long engineerId) {
        long total = orderRepository.countByEngineerId(engineerId);
        long completed = orderRepository.countByEngineerIdAndStatusIn(engineerId,
                List.of(OrderStatus.COMPLETED, OrderStatus.REVIEWED));
        var income = orderRepository.sumIncome(engineerId,
                List.of(OrderStatus.COMPLETED, OrderStatus.REVIEWED));
        var profile = engineerProfileRepository.findById(engineerId).orElse(null);
        return EngineerStatsResponse.builder()
                .totalOrders(total)
                .completedOrders(completed)
                .totalIncome(income)
                .ratingAvg(profile == null ? null : profile.getRatingAvg())
                .onlineStatus(profile != null && Boolean.TRUE.equals(profile.getOnlineStatus()))
                .build();
    }

    private Order loadOwn(Long orderId, Long engineerId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BizException(ErrorCode.ORDER_NOT_FOUND));
        orderActionService.assertEngineerOwns(order, engineerId);
        return order;
    }

    private PoolOrderResponse toPoolItem(Order order, EngineerProfile profile) {
        DeviceCategory category = deviceCategoryRepository.findByIdOrNull(order.getDeviceCategoryId());
        Integer distanceM = null;
        if (profile != null && profile.getLastLng() != null && profile.getLastLat() != null
                && (profile.getLastLng() != 0D || profile.getLastLat() != 0D)) {
            distanceM = (int) GeoUtils.distanceMeters(order.getLng(), order.getLat(),
                    profile.getLastLng(), profile.getLastLat());
        }
        Map<String, Object> snapshot = JsonUtils.readObject(order.getAddressSnapshot());
        return PoolOrderResponse.builder()
                .id(order.getId())
                .orderNo(order.getOrderNo())
                .deviceCategoryName(order.getDeviceCategoryInput() != null
                        ? order.getDeviceCategoryInput()
                        : (category == null ? null : category.getName()))
                .deviceBrand(order.getDeviceBrand())
                .deviceModel(order.getDeviceModel())
                .faultDesc(order.getFaultDesc())
                .addressText(String.valueOf(snapshot.getOrDefault("detail", "")))
                .urgency(order.getUrgency().name())
                .urgencyLabel(order.getUrgency().getLabel())
                .distanceM(distanceM)
                .expectTime(order.getExpectTime())
                .createdAt(order.getCreatedAt())
                .build();
    }

    private OrderResponse toSimpleResponse(Order order) {
        DeviceCategory category = deviceCategoryRepository.findByIdOrNull(order.getDeviceCategoryId());
        String customerName = userRepository.findById(order.getCustomerId()).map(User::getNickname).orElse(null);
        return OrderResponse.from(order, category, customerName, null);
    }

    private OrderStatus parseStatus(String status) {
        try {
            return OrderStatus.valueOf(status.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new BizException(ErrorCode.PARAM_ERROR, "非法的工单状态: " + status);
        }
    }
}
