package com.repairhub.order.dto;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

/**
 * 工单详情：基础信息 + 状态时间轴 + 报价 + 维修报告 + 工程师摘要。
 */
@Data
@Builder
public class OrderDetailResponse {

    private OrderResponse order;
    private List<StatusLogResponse> statusLogs;
    private List<QuoteResponse> quotes;
    private ReportResponse report;
    private EngineerSummary engineer;

    @Data
    @Builder
    public static class ReportResponse {
        private String diagnosis;
        private String solution;
        private List<String> beforePhotos;
        private List<String> afterPhotos;
        private List<String> partsReplaced;
    }

    @Data
    @Builder
    public static class EngineerSummary {
        private Long userId;
        private String realName;
        private String phone;
        private BigDecimal ratingAvg;
        private Integer orderCount;
    }
}
