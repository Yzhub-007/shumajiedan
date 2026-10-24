package com.repairhub.order.entity;

import com.repairhub.common.domain.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

/**
 * 设备类型字典 + 基础价（后台可配置，计划书 2.5 价格体系）。
 */
@Entity
@Table(name = "device_categories")
@Getter
@Setter
public class DeviceCategory extends BaseEntity {

    @Column(name = "parent_id")
    private Long parentId;

    @Column(nullable = false, length = 50)
    private String name;

    @Column(name = "base_fee", nullable = false, precision = 10, scale = 2)
    private BigDecimal baseFee = BigDecimal.ZERO;

    @Column(name = "visit_fee", nullable = false, precision = 10, scale = 2)
    private BigDecimal visitFee = BigDecimal.ZERO;

    @Column(nullable = false)
    private Integer sort = 0;

    @Column(nullable = false)
    private Boolean enabled = true;
}
