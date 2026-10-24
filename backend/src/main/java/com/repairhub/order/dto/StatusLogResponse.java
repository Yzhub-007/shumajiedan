package com.repairhub.order.dto;

import com.repairhub.order.entity.OrderStatusLog;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class StatusLogResponse {

    private String fromStatus;
    private String fromStatusLabel;
    private String toStatus;
    private String toStatusLabel;
    private String operatorRole;
    private String remark;
    private LocalDateTime createdAt;

    public static StatusLogResponse from(OrderStatusLog log) {
        return StatusLogResponse.builder()
                .fromStatus(log.getFromStatus() == null ? null : log.getFromStatus().name())
                .fromStatusLabel(log.getFromStatus() == null ? null : log.getFromStatus().getLabel())
                .toStatus(log.getToStatus() == null ? null : log.getToStatus().name())
                .toStatusLabel(log.getToStatus() == null ? null : log.getToStatus().getLabel())
                .operatorRole(log.getOperatorRole())
                .remark(log.getRemark())
                .createdAt(log.getCreatedAt())
                .build();
    }
}
