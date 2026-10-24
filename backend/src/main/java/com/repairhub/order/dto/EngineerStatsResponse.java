package com.repairhub.order.dto;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;

@Data
@Builder
public class EngineerStatsResponse {

    private long totalOrders;
    private long completedOrders;
    private BigDecimal totalIncome;
    private BigDecimal ratingAvg;
    private Boolean onlineStatus;
}
