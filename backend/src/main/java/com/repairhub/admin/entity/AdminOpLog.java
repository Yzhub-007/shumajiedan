package com.repairhub.admin.entity;

import com.repairhub.common.domain.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/**
 * 后台操作日志：审核/指派/改派/关闭等敏感操作全量留痕（计划书 2.1.8）。
 */
@Entity
@Table(name = "admin_op_logs")
@Getter
@Setter
public class AdminOpLog extends BaseEntity {

    @Column(name = "admin_id", nullable = false)
    private Long adminId;

    @Column(nullable = false, length = 50)
    private String action;

    @Column(length = 100)
    private String target;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    private String detail = "{}";
}
