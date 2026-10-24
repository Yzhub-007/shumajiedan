package com.repairhub.order.service;

import com.repairhub.common.config.OrderProperties;
import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.order.entity.Order;
import com.repairhub.order.entity.OrderStatusLog;
import com.repairhub.order.enums.OrderStatus;
import com.repairhub.order.event.OrderStatusChangedEvent;
import com.repairhub.order.repository.OrderRepository;
import com.repairhub.order.repository.OrderStatusLogRepository;
import com.repairhub.order.state.OrderAction;
import com.repairhub.order.state.OrderStateMachine;
import com.repairhub.user.entity.UserRole;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * 工单状态变更统一入口：所有动作必须经过状态机校验，并落状态流水 + 发事件。
 */
@Service
@RequiredArgsConstructor
public class OrderActionService {

    private final OrderRepository orderRepository;
    private final OrderStatusLogRepository statusLogRepository;
    private final ApplicationEventPublisher eventPublisher;
    private final OrderProperties orderProperties;

    @Transactional
    public Order apply(Long orderId, OrderAction action, Long operatorId, UserRole role, String remark) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BizException(ErrorCode.ORDER_NOT_FOUND));
        OrderStatus from = order.getStatus();
        OrderStatus to = OrderStateMachine.validate(from, action, role);
        if (action == OrderAction.CONFIRM_FINISH && orderProperties.isPaymentEnabled()) {
            // V1.1 开启支付：验收通过先进入待支付（计划书 2.2）
            to = OrderStatus.PENDING_PAYMENT;
        }
        order.setStatus(to);

        LocalDateTime now = LocalDateTime.now();
        switch (action) {
            case ARRIVE -> order.setArrivedAt(now);
            case START_REPAIR, QUOTE_ACCEPT -> order.setRepairStartedAt(now);
            case FINISH -> order.setFinishedAt(now);
            case CONFIRM_FINISH -> order.setConfirmedAt(now);
            case PAY -> order.setPaidAt(now);
            case CANCEL -> {
                order.setCancelledAt(now);
                order.setCancelBy(operatorId);
                if (remark != null && !remark.isBlank()) {
                    order.setCancelReason(remark);
                }
            }
            default -> {
            }
        }
        orderRepository.save(order);

        OrderStatusLog logEntry = new OrderStatusLog();
        logEntry.setOrderId(orderId);
        logEntry.setFromStatus(from);
        logEntry.setToStatus(to);
        logEntry.setOperatorId(operatorId);
        logEntry.setOperatorRole(role.name());
        logEntry.setRemark(remark);
        statusLogRepository.save(logEntry);

        eventPublisher.publishEvent(new OrderStatusChangedEvent(orderId, from, to, action, operatorId));
        return order;
    }

    public void assertEngineerOwns(Order order, Long engineerId) {
        if (order.getEngineerId() == null || !order.getEngineerId().equals(engineerId)) {
            throw new BizException(ErrorCode.FORBIDDEN, "该工单不属于当前工程师");
        }
    }
}
