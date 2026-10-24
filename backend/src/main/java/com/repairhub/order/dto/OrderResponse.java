package com.repairhub.order.dto;

import com.repairhub.common.util.JsonUtils;
import com.repairhub.order.entity.DeviceCategory;
import com.repairhub.order.entity.Order;
import com.repairhub.order.enums.Urgency;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Data
@Builder
public class OrderResponse {

    private Long id;
    private String orderNo;
    private Long customerId;
    private Long engineerId;
    private String engineerName;
    private Long deviceCategoryId;
    private String deviceCategoryName;
    private String deviceBrand;
    private String deviceModel;
    private String faultDesc;
    private List<String> mediaUrls;
    private String addressText;
    private Double lng;
    private Double lat;
    private String urgency;
    private String urgencyLabel;
    private LocalDateTime expectTime;
    private String status;
    private String statusLabel;
    private BigDecimal quoteAmount;
    private BigDecimal finalAmount;
    private BigDecimal estimatedAmount;
    private LocalDateTime createdAt;

    public static OrderResponse from(Order order, DeviceCategory category,
                                     String engineerName, BigDecimal estimatedAmount) {
        Map<String, Object> snapshot = JsonUtils.readObject(order.getAddressSnapshot());
        String addressText = String.valueOf(snapshot.getOrDefault("detail", ""));
        Object label = snapshot.get("label");
        if (label != null && !String.valueOf(label).isBlank()) {
            addressText = label + " " + addressText;
        }
        return OrderResponse.builder()
                .id(order.getId())
                .orderNo(order.getOrderNo())
                .customerId(order.getCustomerId())
                .engineerId(order.getEngineerId())
                .engineerName(engineerName)
                .deviceCategoryId(order.getDeviceCategoryId())
                .deviceCategoryName(category == null ? null : category.getName())
                .deviceBrand(order.getDeviceBrand())
                .deviceModel(order.getDeviceModel())
                .faultDesc(order.getFaultDesc())
                .mediaUrls(JsonUtils.readStringArray(order.getMediaUrls()))
                .addressText(addressText)
                .lng(order.getLng())
                .lat(order.getLat())
                .urgency(order.getUrgency() == null ? null : order.getUrgency().name())
                .urgencyLabel(order.getUrgency() == null ? null : order.getUrgency().getLabel())
                .expectTime(order.getExpectTime())
                .status(order.getStatus().name())
                .statusLabel(order.getStatus().getLabel())
                .quoteAmount(order.getQuoteAmount())
                .finalAmount(order.getFinalAmount())
                .estimatedAmount(estimatedAmount)
                .createdAt(order.getCreatedAt())
                .build();
    }
}
