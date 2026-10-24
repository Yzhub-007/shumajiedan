package com.repairhub.dispatch.entity;

import com.repairhub.common.domain.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "dispatch_records", indexes = @Index(name = "idx_dispatch_order", columnList = "order_id"))
@Getter
@Setter
public class DispatchRecord extends BaseEntity {

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(name = "engineer_id", nullable = false)
    private Long engineerId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private DispatchType type;

    @Column(name = "distance_m")
    private Integer distanceM;
}
