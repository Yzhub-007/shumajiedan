package com.repairhub.order.entity;

import com.repairhub.common.domain.BaseEntity;
import com.repairhub.order.enums.QuoteStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;

/**
 * 现场报价：工时费 + 配件费（计划书 2.4 / 第 6 节）。
 */
@Entity
@Table(name = "order_quotes", indexes = @Index(name = "idx_quotes_order", columnList = "order_id"))
@Getter
@Setter
public class OrderQuote extends BaseEntity {

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(name = "engineer_id", nullable = false)
    private Long engineerId;

    @Column(name = "labor_fee", nullable = false, precision = 10, scale = 2)
    private BigDecimal laborFee = BigDecimal.ZERO;

    @Column(name = "parts_fee", nullable = false, precision = 10, scale = 2)
    private BigDecimal partsFee = BigDecimal.ZERO;

    /** JSON 数组字符串：配件明细 [{name, qty, price}] */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "parts_detail", columnDefinition = "jsonb")
    private String partsDetail = "[]";

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal total = BigDecimal.ZERO;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private QuoteStatus status = QuoteStatus.PENDING;
}
