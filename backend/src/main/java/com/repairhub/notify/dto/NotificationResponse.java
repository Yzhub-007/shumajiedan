package com.repairhub.notify.dto;

import com.repairhub.common.util.JsonUtils;
import com.repairhub.notify.entity.Notification;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.Map;

@Data
@Builder
public class NotificationResponse {

    private Long id;
    private String type;
    private String title;
    private String body;
    private Map<String, Object> data;
    private boolean read;
    private LocalDateTime createdAt;

    public static NotificationResponse from(Notification notification) {
        return NotificationResponse.builder()
                .id(notification.getId())
                .type(notification.getType())
                .title(notification.getTitle())
                .body(notification.getBody())
                .data(JsonUtils.readObject(notification.getData()))
                .read(notification.getReadAt() != null)
                .createdAt(notification.getCreatedAt())
                .build();
    }
}
