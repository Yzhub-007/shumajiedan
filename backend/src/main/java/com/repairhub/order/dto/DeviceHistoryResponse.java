package com.repairhub.order.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

/** 历史记忆推荐：用户历史工单的设备组合（发单页一键填充） */
@Data
@Builder
public class DeviceHistoryResponse {

    private String deviceType;

    private String deviceBrand;

    private String deviceModel;

    private Long useCount;

    private LocalDateTime lastUsedAt;
}
