package com.repairhub.order.event;

/**
 * 工单创建事件：dispatch 模块监听后执行派单（模块解耦，计划书 5 模块化单体）。
 */
public record OrderCreatedEvent(Long orderId) {
}
