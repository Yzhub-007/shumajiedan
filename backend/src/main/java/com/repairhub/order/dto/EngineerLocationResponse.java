package com.repairhub.order.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 工程师当前位置（客户端实时地图用）。
 */
@Data
@Builder
public class EngineerLocationResponse {

    private Long engineerId;
    private Double lng;
    private Double lat;
    private LocalDateTime updatedAt;
}
