package com.repairhub.order.entity;

import com.repairhub.common.domain.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/**
 * 维修报告：完工提交时创建（计划书 3.1.7）。
 */
@Entity
@Table(name = "repair_reports", indexes = @Index(name = "idx_reports_order", columnList = "order_id"))
@Getter
@Setter
public class RepairReport extends BaseEntity {

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(length = 2000)
    private String diagnosis;

    @Column(length = 2000)
    private String solution;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "before_photos", columnDefinition = "jsonb")
    private String beforePhotos = "[]";

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "after_photos", columnDefinition = "jsonb")
    private String afterPhotos = "[]";

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "parts_replaced", columnDefinition = "jsonb")
    private String partsReplaced = "[]";
}
