package com.repairhub.order.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.common.response.PageResult;
import com.repairhub.order.dto.CreateOrderRequest;
import com.repairhub.order.dto.DeviceHistoryResponse;
import com.repairhub.order.dto.OrderDetailResponse;
import com.repairhub.order.dto.OrderResponse;
import com.repairhub.order.dto.QuoteResponse;
import com.repairhub.order.dto.StatusLogResponse;
import com.repairhub.order.entity.DeviceCategory;
import com.repairhub.order.entity.Order;
import com.repairhub.order.entity.OrderQuote;
import com.repairhub.order.entity.OrderStatusLog;
import com.repairhub.order.entity.RepairReport;
import com.repairhub.order.enums.OrderStatus;
import com.repairhub.order.enums.Urgency;
import com.repairhub.order.event.OrderCreatedEvent;
import com.repairhub.order.repository.DeviceCategoryRepository;
import com.repairhub.order.repository.OrderQuoteRepository;
import com.repairhub.order.repository.OrderRepository;
import com.repairhub.order.repository.OrderStatusLogRepository;
import com.repairhub.order.repository.RepairReportRepository;
import com.repairhub.user.entity.EngineerProfile;
import com.repairhub.user.entity.User;
import com.repairhub.user.entity.UserRole;
import com.repairhub.user.repository.AddressRepository;
import com.repairhub.user.repository.EngineerProfileRepository;
import com.repairhub.user.repository.UserRepository;
import com.repairhub.user.entity.Address;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

/**
 * 工单服务：创建（校验/订单号/地址快照/预估费用）、列表、详情（计划书 2.1.5 / 2.1.6）。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class OrderService {

    private static final DateTimeFormatter ORDER_NO_FORMAT = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

    private final OrderRepository orderRepository;
    private final OrderStatusLogRepository statusLogRepository;
    private final DeviceCategoryRepository deviceCategoryRepository;
    private final OrderQuoteRepository quoteRepository;
    private final RepairReportRepository reportRepository;
    private final AddressRepository addressRepository;
    private final UserRepository userRepository;
    private final EngineerProfileRepository engineerProfileRepository;
    private final OrderActionService orderActionService;
    private final ApplicationEventPublisher eventPublisher;
    private final ObjectMapper objectMapper;

    @Transactional
    public OrderResponse create(CreateOrderRequest request, Long customerId) {
        String typeInput = request.getDeviceCategoryInput() == null
                ? null : request.getDeviceCategoryInput().trim();
        if (request.getDeviceCategoryId() == null && (typeInput == null || typeInput.isBlank())) {
            throw new BizException(ErrorCode.PARAM_ERROR, "设备类型不能为空");
        }
        DeviceCategory category;
        if (request.getDeviceCategoryId() != null) {
            category = deviceCategoryRepository.findById(request.getDeviceCategoryId())
                    .filter(c -> Boolean.TRUE.equals(c.getEnabled()))
                    .orElseThrow(() -> new BizException(ErrorCode.NOT_FOUND, "设备类型不存在或已停用"));
        } else {
            // 手动输入：文本与启用字典名一致时回填关联，保留计价与技能匹配
            category = deviceCategoryRepository.findFirstByNameIgnoreCaseAndEnabledTrue(typeInput)
                    .orElse(null);
        }
        // 冗余名称快照：字典后续改名/停用不影响历史工单展示与推荐
        if (typeInput == null && category != null) {
            typeInput = category.getName();
        }
        Address address = addressRepository.findById(request.getAddressId())
                .filter(a -> a.getUserId().equals(customerId))
                .orElseThrow(() -> new BizException(ErrorCode.NOT_FOUND, "服务地址不存在"));

        Urgency urgency = parseUrgency(request.getUrgency());
        Order order = new Order();
        order.setOrderNo(nextOrderNo());
        order.setCustomerId(customerId);
        order.setDeviceCategoryId(category == null ? null : category.getId());
        order.setDeviceCategoryInput(typeInput);
        order.setDeviceBrand(request.getDeviceBrand());
        order.setDeviceModel(request.getDeviceModel());
        order.setFaultDesc(request.getFaultDesc());
        order.setMediaUrls(toJson(request.getMediaUrls()));
        order.setAddressId(address.getId());
        order.setAddressSnapshot(addressSnapshot(address));
        order.setLng(address.getLng() == null ? 0D : address.getLng());
        order.setLat(address.getLat() == null ? 0D : address.getLat());
        order.setUrgency(urgency);
        order.setExpectTime(request.getExpectTime());
        orderRepository.save(order);

        saveLog(order.getId(), null, OrderStatus.PENDING, customerId, UserRole.CUSTOMER, "发布工单");
        // 触发派单（dispatch 模块监听）
        eventPublisher.publishEvent(new OrderCreatedEvent(order.getId()));

        return OrderResponse.from(order, category, null, estimate(category, urgency));
    }

    @Transactional(readOnly = true)
    public PageResult<OrderResponse> pageCustomerOrders(Long customerId, String status, int page, int size) {
        Pageable pageable = PageRequest.of(Math.max(page - 1, 0), Math.min(size, 50),
                Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Order> result = (status == null || status.isBlank())
                ? orderRepository.findByCustomerId(customerId, pageable)
                : orderRepository.findByCustomerIdAndStatus(customerId, parseStatus(status), pageable);
        return PageResult.of(result, order -> toSimpleResponse(order));
    }

    /** 历史记忆推荐：该用户历史工单的设备组合（类型+品牌+型号）去重，按最近使用排序 */
    @Transactional(readOnly = true)
    public List<DeviceHistoryResponse> deviceHistory(Long customerId, int limit) {
        return orderRepository.findDeviceHistory(customerId, Math.max(1, Math.min(limit, 20))).stream()
                .map(r -> DeviceHistoryResponse.builder()
                        .deviceType(r.getDeviceType())
                        .deviceBrand(r.getDeviceBrand())
                        .deviceModel(r.getDeviceModel())
                        .useCount(r.getUseCount())
                        .lastUsedAt(r.getLastUsedAt() == null ? null : r.getLastUsedAt().toLocalDateTime())
                        .build())
                .toList();
    }

    @Transactional(readOnly = true)
    public OrderDetailResponse detail(Long orderId, Long callerId, UserRole role) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BizException(ErrorCode.ORDER_NOT_FOUND));
        checkReadable(order, callerId, role);

        DeviceCategory category = deviceCategoryRepository.findByIdOrNull(order.getDeviceCategoryId());
        OrderResponse orderResponse = toSimpleResponse(order, category);

        List<StatusLogResponse> logs = statusLogRepository
                .findByOrderIdOrderByCreatedAtAscIdAsc(orderId).stream()
                .map(StatusLogResponse::from).toList();

        List<QuoteResponse> quotes = quoteRepository
                .findByOrderIdOrderByCreatedAtDescIdDesc(orderId).stream()
                .map(QuoteResponse::from).toList();

        OrderDetailResponse.ReportResponse report = reportRepository
                .findFirstByOrderIdOrderByCreatedAtDescIdDesc(orderId)
                .map(this::toReportResponse).orElse(null);

        OrderDetailResponse.EngineerSummary engineer = null;
        if (order.getEngineerId() != null) {
            engineer = engineerProfileRepository.findById(order.getEngineerId())
                    .map(profile -> OrderDetailResponse.EngineerSummary.builder()
                            .userId(profile.getUserId())
                            .realName(profile.getRealName())
                            .phone(userRepository.findById(profile.getUserId()).map(User::getPhone).orElse(null))
                            .ratingAvg(profile.getRatingAvg())
                            .orderCount(profile.getOrderCount())
                            .build())
                    .orElse(null);
        }
        return OrderDetailResponse.builder()
                .order(orderResponse)
                .statusLogs(logs)
                .quotes(quotes)
                .report(report)
                .engineer(engineer)
                .build();
    }

    /** 客户取消工单（含各状态规则，计划书 3.1.8） */
    @Transactional
    public void cancel(Long orderId, Long customerId, String reason) {
        orderActionService.apply(orderId, com.repairhub.order.state.OrderAction.CANCEL,
                customerId, UserRole.CUSTOMER, reason);
    }

    /** 客户查看工程师当前位置 */
    @Transactional(readOnly = true)
    public OrderDetailResponse.EngineerSummary engineerSummary(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BizException(ErrorCode.ORDER_NOT_FOUND));
        if (order.getEngineerId() == null) {
            return null;
        }
        return engineerProfileRepository.findById(order.getEngineerId())
                .map(profile -> OrderDetailResponse.EngineerSummary.builder()
                        .userId(profile.getUserId())
                        .realName(profile.getRealName())
                        .phone(userRepository.findById(profile.getUserId()).map(User::getPhone).orElse(null))
                        .ratingAvg(profile.getRatingAvg())
                        .orderCount(profile.getOrderCount())
                        .build())
                .orElse(null);
    }

    private void checkReadable(Order order, Long callerId, UserRole role) {
        boolean allowed = switch (role) {
            case CUSTOMER -> callerId.equals(order.getCustomerId());
            case ENGINEER -> callerId.equals(order.getEngineerId());
            case ADMIN, SYSTEM -> true;
        };
        if (!allowed) {
            throw new BizException(ErrorCode.FORBIDDEN);
        }
    }

    private OrderResponse toSimpleResponse(Order order) {
        DeviceCategory category = deviceCategoryRepository.findByIdOrNull(order.getDeviceCategoryId());
        return toSimpleResponse(order, category);
    }

    private OrderResponse toSimpleResponse(Order order, DeviceCategory category) {
        String engineerName = null;
        if (order.getEngineerId() != null) {
            engineerName = userRepository.findById(order.getEngineerId()).map(User::getNickname).orElse(null);
        }
        return OrderResponse.from(order, category, engineerName, null);
    }

    private OrderDetailResponse.ReportResponse toReportResponse(RepairReport report) {
        return OrderDetailResponse.ReportResponse.builder()
                .diagnosis(report.getDiagnosis())
                .solution(report.getSolution())
                .beforePhotos(com.repairhub.common.util.JsonUtils.readStringArray(report.getBeforePhotos()))
                .afterPhotos(com.repairhub.common.util.JsonUtils.readStringArray(report.getAfterPhotos()))
                .partsReplaced(com.repairhub.common.util.JsonUtils.readStringArray(report.getPartsReplaced()))
                .build();
    }

    /** 估算费用：自由输入且未匹配字典时无基础价，返回 null（实际金额以工程师报价为准） */
    private BigDecimal estimate(DeviceCategory category, Urgency urgency) {
        if (category == null) {
            return null;
        }
        BigDecimal base = category.getBaseFee() == null ? BigDecimal.ZERO : category.getBaseFee();
        BigDecimal visit = category.getVisitFee() == null ? BigDecimal.ZERO : category.getVisitFee();
        return base.multiply(BigDecimal.valueOf(urgency.getSurchargeMultiplier()))
                .add(visit).setScale(2, RoundingMode.HALF_UP);
    }

    private String addressSnapshot(Address address) {
        try {
            Map<String, Object> snapshot = new java.util.LinkedHashMap<>();
            snapshot.put("label", address.getLabel());
            snapshot.put("province", address.getProvince());
            snapshot.put("city", address.getCity());
            snapshot.put("district", address.getDistrict());
            snapshot.put("detail", address.getDetail());
            return objectMapper.writeValueAsString(snapshot);
        } catch (Exception e) {
            return "{}";
        }
    }

    private String toJson(List<String> list) {
        try {
            return objectMapper.writeValueAsString(list == null ? List.of() : list);
        } catch (Exception e) {
            return "[]";
        }
    }

    private String nextOrderNo() {
        String candidate;
        do {
            candidate = "RH" + LocalDateTime.now().format(ORDER_NO_FORMAT)
                    + String.format("%04d", ThreadLocalRandom.current().nextInt(10000));
        } while (orderRepository.existsByOrderNo(candidate));
        return candidate;
    }

    private void saveLog(Long orderId, OrderStatus from, OrderStatus to,
                         Long operatorId, UserRole role, String remark) {
        OrderStatusLog logEntry = new OrderStatusLog();
        logEntry.setOrderId(orderId);
        logEntry.setFromStatus(from);
        logEntry.setToStatus(to);
        logEntry.setOperatorId(operatorId);
        logEntry.setOperatorRole(role.name());
        logEntry.setRemark(remark);
        statusLogRepository.save(logEntry);
    }

    private Urgency parseUrgency(String urgency) {
        if (urgency == null || urgency.isBlank()) {
            return Urgency.NORMAL;
        }
        try {
            return Urgency.valueOf(urgency.toUpperCase());
        } catch (IllegalArgumentException e) {
            return Urgency.NORMAL;
        }
    }

    private OrderStatus parseStatus(String status) {
        try {
            return OrderStatus.valueOf(status.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new BizException(ErrorCode.PARAM_ERROR, "非法的工单状态: " + status);
        }
    }
}
