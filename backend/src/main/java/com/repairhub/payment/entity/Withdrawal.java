package com.repairhub.payment.entity;

import com.repairhub.common.domain.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;

/**
 * 提现申请（计划书第 6 节 withdrawals 表）。
 * 申请：balance → frozen；审核通过：frozen 扣减（实际打款渠道见 TODO(V1.1)）；拒绝：frozen 退回 balance。
 */
@Entity
@Table(name = "withdrawals")
@Getter
@Setter
public class Withdrawal extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal amount;

    /** PENDING / APPROVED / REJECTED */
    @Column(nullable = false, length = 20)
    private String status = "PENDING";

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "account_info", columnDefinition = "jsonb")
    private String accountInfo = "{}";

    @Column(name = "reviewed_by")
    private Long reviewedBy;

    @Column(name = "reject_reason", length = 200)
    private String rejectReason;
}
