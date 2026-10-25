package com.repairhub.payment.entity;

import com.repairhub.common.domain.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 支付流水（计划书第 6 节 payments 表）。V1.1 接入微信/支付宝；
 * 当前 MOCK 渠道直接成功，回调幂等要求见 TODO(V1.1)。
 */
@Entity
@Table(name = "payments", indexes = @Index(name = "idx_payments_order", columnList = "order_id"))
@Getter
@Setter
public class Payment extends BaseEntity {

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal amount;

    /** MOCK / WECHAT / ALIPAY */
    @Column(nullable = false, length = 20)
    private String channel;

    @Column(name = "trade_no", length = 64)
    private String tradeNo;

    /** CREATED / PAID / CLOSED */
    @Column(nullable = false, length = 20)
    private String status = "CREATED";

    @Column(name = "paid_at")
    private LocalDateTime paidAt;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "raw_callback", columnDefinition = "jsonb")
    private String rawCallback;
}
