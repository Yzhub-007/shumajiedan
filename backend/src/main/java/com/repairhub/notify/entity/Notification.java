package com.repairhub.notify.entity;

import com.repairhub.common.domain.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;

@Entity
@Table(name = "notifications", indexes = @Index(name = "idx_notifications_user", columnList = "user_id, created_at"))
@Getter
@Setter
public class Notification extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private Long userId;

    /** NEW_ORDER / ORDER_ACCEPTED / ORDER_STATUS / VERIFY_RESULT ... */
    @Column(nullable = false, length = 30)
    private String type;

    @Column(nullable = false, length = 100)
    private String title;

    @Column(length = 500)
    private String body;

    /** JSON：跳转参数等，如 {"orderId":1} */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    private String data = "{}";

    private LocalDateTime readAt;
}
