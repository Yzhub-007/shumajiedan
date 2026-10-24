package com.repairhub.order.event;

import com.repairhub.order.enums.OrderStatus;
import com.repairhub.order.state.OrderAction;

/**
 * 工单状态变更事件：notify 模块监听后广播 WebSocket / 发送通知。
 */
public record OrderStatusChangedEvent(Long orderId, OrderStatus from, OrderStatus to,
                                      OrderAction action, Long operatorId) {
}
