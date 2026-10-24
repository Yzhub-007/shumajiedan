package com.repairhub.admin.service;

import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.common.response.PageResult;
import com.repairhub.dispatch.service.DispatchService;
import com.repairhub.notify.service.NotificationService;
import com.repairhub.order.dto.OrderResponse;
import com.repairhub.order.entity.Order;
import com.repairhub.order.entity.OrderStatusLog;
import com.repairhub.order.enums.OrderStatus;
import com.repairhub.order.repository.DeviceCategoryRepository;
import com.repairhub.order.repository.OrderRepository;
import com.repairhub.order.repository.OrderStatusLogRepository;
import com.repairhub.order.service.OrderActionService;
import com.repairhub.order.state.OrderAction;
import com.repairhub.user.entity.User;
import com.repairhub.user.entity.UserRole;
import com.repairhub.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

/**
 * 后台工单操作：列表检索、指派、改派、关闭（计划书 3.3.1）。
 */
@Service
@RequiredArgsConstructor
public class AdminOrderService {

    private final OrderRepository orderRepository;
    private final OrderStatusLogRepository statusLogRepository;
    private final DeviceCategoryRepository deviceCategoryRepository;
    private final UserRepository userRepository;
    private final OrderActionService orderActionService;
    private final DispatchService dispatchService;
    private final NotificationService notificationService;
    private final AdminOpLogService opLogService;

    @Transactional(readOnly = true)
    public PageResult<OrderResponse> page(String status, String keyword, int page, int size) {
        Pageable pageable = PageRequest.of(Math.max(page - 1, 0), Math.min(size, 100),
                Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Order> result;
        if (keyword != null && !keyword.isBlank()) {
            result = orderRepository.findByOrderNoContainingIgnoreCase(keyword.trim(), pageable);
        } else if (status != null && !status.isBlank()) {
            result = orderRepository.findByStatus(parseStatus(status), pageable);
        } else {
            result = orderRepository.findAll(pageable);
        }
        return PageResult.of(result, this::toResponse);
    }

    /** 指派工程师（仅待接单） */
    @Transactional
    public void assign(Long orderId, Long engineerId, Long adminId) {
        Order order = requireOrder(orderId);
        if (order.getStatus() != OrderStatus.PENDING) {
            throw new BizException(ErrorCode.ORDER_STATE_ILLEGAL, "仅待接单工单可指派");
        }
        order.setEngineerId(engineerId);
        orderRepository.save(order);
        orderActionService.apply(orderId, OrderAction.ASSIGN, adminId, UserRole.ADMIN, "后台指派");
        dispatchService.recordAssign(orderId, engineerId);
        opLogService.record(adminId, "ORDER_ASSIGN", "order:" + orderId, Map.of("engineerId", engineerId));
    }

    /** 改派（仅已接单未出发）：换工程师，工单状态保持 ACCEPTED */
    @Transactional
    public void reassign(Long orderId, Long engineerId, Long adminId) {
        Order order = requireOrder(orderId);
        if (order.getStatus() != OrderStatus.ACCEPTED) {
            throw new BizException(ErrorCode.ORDER_STATE_ILLEGAL, "仅已接单工单可改派");
        }
        Long oldEngineerId = order.getEngineerId();
        order.setEngineerId(engineerId);
        orderRepository.save(order);

        OrderStatusLog logEntry = new OrderStatusLog();
        logEntry.setOrderId(orderId);
        logEntry.setFromStatus(OrderStatus.ACCEPTED);
        logEntry.setToStatus(OrderStatus.ACCEPTED);
        logEntry.setOperatorId(adminId);
        logEntry.setOperatorRole(UserRole.ADMIN.name());
        logEntry.setRemark("改派工程师 " + oldEngineerId + " → " + engineerId);
        statusLogRepository.save(logEntry);

        dispatchService.recordAssign(orderId, engineerId);
        if (oldEngineerId != null) {
            notificationService.send(oldEngineerId, "ORDER_RELEASED", "工单已改派",
                    "您接的工单已被平台改派，请查看其他工单", Map.of("orderId", orderId));
        }
        opLogService.record(adminId, "ORDER_REASSIGN", "order:" + orderId,
                Map.of("from", oldEngineerId, "to", engineerId));
    }

    /** 关闭工单：待接单/已接单按取消处理；维修中按无法修复关闭 */
    @Transactional
    public void close(Long orderId, String reason, Long adminId) {
        Order order = requireOrder(orderId);
        switch (order.getStatus()) {
            case PENDING, ACCEPTED ->
                    orderActionService.apply(orderId, OrderAction.CANCEL, adminId, UserRole.ADMIN, reason);
            case REPAIRING ->
                    orderActionService.apply(orderId, OrderAction.CLOSE_UNRESOLVED, adminId, UserRole.ADMIN, reason);
            default -> throw new BizException(ErrorCode.ORDER_STATE_ILLEGAL, "当前状态不可关闭");
        }
        opLogService.record(adminId, "ORDER_CLOSE", "order:" + orderId, Map.of("reason", reason));
    }

    private Order requireOrder(Long orderId) {
        return orderRepository.findById(orderId)
                .orElseThrow(() -> new BizException(ErrorCode.ORDER_NOT_FOUND));
    }

    private OrderResponse toResponse(Order order) {
        var category = deviceCategoryRepository.findById(order.getDeviceCategoryId()).orElse(null);
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
