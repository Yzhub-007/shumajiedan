package com.repairhub.order.entity;

import com.repairhub.common.domain.BaseEntity;
import com.repairhub.order.enums.OrderStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

/**
 * 工单状态流水：所有状态转移必须落一条记录（计划书 5.1.4）。
 */
@Entity
@Table(name = "order_status_logs", indexes = @Index(name = "idx_status_logs_order", columnList = "order_id"))
@Getter
@Setter
public class OrderStatusLog extends BaseEntity {

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Enumerated(EnumType.STRING)
    @Column(name = "from_status", length = 30)
    private OrderStatus fromStatus;

    @Enumerated(EnumType.STRING)
    @Column(name = "to_status", nullable = false, length = 30)
    private OrderStatus toStatus;

    @Column(name = "operator_id")
    private Long operatorId;

    /** 记录操作时的角色字符串（CUSTOMER/ENGINEER/ADMIN/SYSTEM） */
    @Column(name = "operator_role", length = 20)
    private String operatorRole;

    @Column(length = 200)
    private String remark;
}
