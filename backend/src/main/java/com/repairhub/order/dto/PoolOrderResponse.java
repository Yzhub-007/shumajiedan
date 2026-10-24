package com.repairhub.order.dto;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 工单池条目（工程师端）：按距离排序展示。
 */
@Data
@Builder
public class PoolOrderResponse {

    private Long id;
    private String orderNo;
    private String deviceCategoryName;
    private String deviceBrand;
    private String deviceModel;
    private String faultDesc;
    private String addressText;
    private String urgency;
    private String urgencyLabel;
    private Integer distanceM;
    private BigDecimal estimatedAmount;
    private LocalDateTime expectTime;
    private LocalDateTime createdAt;
}
