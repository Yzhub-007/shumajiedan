package com.repairhub.order.dto;

import com.repairhub.common.util.JsonUtils;
import com.repairhub.order.entity.OrderQuote;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class QuoteResponse {

    private Long id;
    private Long orderId;
    private Long engineerId;
    private BigDecimal laborFee;
    private BigDecimal partsFee;
    private List<String> partsDetail;
    private BigDecimal total;
    private String status;
    private String statusLabel;
    private LocalDateTime createdAt;

    public static QuoteResponse from(OrderQuote quote) {
        return QuoteResponse.builder()
                .id(quote.getId())
                .orderId(quote.getOrderId())
                .engineerId(quote.getEngineerId())
                .laborFee(quote.getLaborFee())
                .partsFee(quote.getPartsFee())
                .partsDetail(JsonUtils.readStringArray(quote.getPartsDetail()))
                .total(quote.getTotal())
                .status(quote.getStatus().name())
                .statusLabel(quote.getStatus().getLabel())
                .createdAt(quote.getCreatedAt())
                .build();
    }
}
