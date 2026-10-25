package com.repairhub.order.entity;

import com.repairhub.common.domain.BaseEntity;
import com.repairhub.order.enums.OrderStatus;
import com.repairhub.order.enums.Urgency;
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
import java.time.LocalDateTime;

/**
 * 工单。地址写入时生成 address_snapshot 快照（JSON 字符串），后续地址修改不影响历史工单。
 */
@Entity
@Table(name = "orders", indexes = {
        @Index(name = "idx_orders_status_created", columnList = "status, created_at"),
        @Index(name = "idx_orders_customer", columnList = "customer_id"),
        @Index(name = "idx_orders_engineer", columnList = "engineer_id")
})
@Getter
@Setter
public class Order extends BaseEntity {

    @Column(name = "order_no", nullable = false, unique = true, length = 32)
    private String orderNo;

    @Column(name = "customer_id", nullable = false)
    private Long customerId;

    @Column(name = "engineer_id")
    private Long engineerId;

    /** 手动输入设备类型时可为空；与 deviceCategoryInput 二选一 */
    @Column(name = "device_category_id")
    private Long deviceCategoryId;

    /** 用户实际输入的设备类型文本（选中字典项时也冗余保存，历史推荐用） */
    @Column(name = "device_category_input", length = 50)
    private String deviceCategoryInput;

    @Column(name = "device_brand", length = 50)
    private String deviceBrand;

    @Column(name = "device_model", length = 50)
    private String deviceModel;

    @Column(name = "fault_desc", nullable = false, length = 2000)
    private String faultDesc;

    /** JSON 数组字符串：图片/视频 URL */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "media_urls", columnDefinition = "jsonb")
    private String mediaUrls = "[]";

    @Column(name = "address_id")
    private Long addressId;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "address_snapshot", columnDefinition = "jsonb")
    private String addressSnapshot = "{}";

    private Double lng = 0D;

    private Double lat = 0D;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Urgency urgency = Urgency.NORMAL;

    @Column(name = "expect_time")
    private LocalDateTime expectTime;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private OrderStatus status = OrderStatus.PENDING;

    @Column(name = "quote_amount", precision = 10, scale = 2)
    private BigDecimal quoteAmount;

    @Column(name = "final_amount", precision = 10, scale = 2)
    private BigDecimal finalAmount;

    @Column(name = "platform_fee", precision = 10, scale = 2)
    private BigDecimal platformFee;

    private LocalDateTime acceptedAt;
    private LocalDateTime arrivedAt;
    private LocalDateTime repairStartedAt;
    private LocalDateTime finishedAt;
    private LocalDateTime confirmedAt;
    private LocalDateTime paidAt;
    private LocalDateTime cancelledAt;

    @Column(name = "cancel_reason", length = 500)
    private String cancelReason;

    @Column(name = "cancel_by")
    private Long cancelBy;
}
