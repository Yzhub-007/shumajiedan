package com.repairhub.order.enums;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 工单状态（计划书 2.2 状态机）。唯一合法转移定义见 {@link com.repairhub.order.state.OrderStateMachine}。
 */
@Getter
@AllArgsConstructor
public enum OrderStatus {

    PENDING("待接单"),
    ACCEPTED("已接单"),
    ON_THE_WAY("前往中"),
    ARRIVED("已到达"),
    REPAIRING("维修中"),
    PENDING_CONFIRM("待验收"),
    PENDING_PAYMENT("待支付"),
    COMPLETED("已完成"),
    REVIEWED("已评价"),
    CANCELLED("已取消"),
    CLOSED_UNRESOLVED("无法修复已关闭");

    private final String label;
}
