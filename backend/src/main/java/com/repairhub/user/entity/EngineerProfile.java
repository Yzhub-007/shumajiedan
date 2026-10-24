package com.repairhub.user.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 工程师资料与认证（主键 = user_id）。
 * 注意：DB 中的 location 为 PostGIS 生成列（由 last_lng/last_lat 派生），实体不映射。
 */
@Entity
@Table(name = "engineer_profiles")
@Getter
@Setter
public class EngineerProfile {

    @Id
    private Long userId;

    @Column(name = "real_name", length = 50)
    private String realName;

    @Column(name = "id_card_no", length = 100)
    private String idCardNo;

    @Column(name = "id_card_front_url", length = 500)
    private String idCardFrontUrl;

    @Column(name = "id_card_back_url", length = 500)
    private String idCardBackUrl;

    /** JSON 数组字符串，如 ["https://oss/xx/a.jpg"] */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "cert_urls", columnDefinition = "jsonb")
    private String certUrls = "[]";

    /** JSON 数组字符串，如 ["注塑机","制冷设备"] */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "skill_tags", columnDefinition = "jsonb")
    private String skillTags = "[]";

    @Column(name = "service_radius_km", nullable = false)
    private Integer serviceRadiusKm = 10;

    @Enumerated(EnumType.STRING)
    @Column(name = "verify_status", nullable = false, length = 20)
    private VerifyStatus verifyStatus = VerifyStatus.PENDING;

    @Column(name = "reject_reason", length = 500)
    private String rejectReason;

    @Column(name = "rating_avg", nullable = false, precision = 3, scale = 2)
    private BigDecimal ratingAvg = BigDecimal.valueOf(5.00);

    @Column(name = "order_count", nullable = false)
    private Integer orderCount = 0;

    @Column(name = "online_status", nullable = false)
    private Boolean onlineStatus = false;

    private Double lastLng = 0D;

    private Double lastLat = 0D;

    @Column(name = "last_location_at")
    private LocalDateTime lastLocationAt;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
