package com.repairhub.notify.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.common.response.PageResult;
import com.repairhub.notify.dto.NotificationResponse;
import com.repairhub.notify.entity.Notification;
import com.repairhub.notify.repository.NotificationRepository;
import com.repairhub.notify.service.push.PushSender;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * 通知服务：站内信落库 + 系统推送（计划书 3.1.10）。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final PushSender pushSender;
    private final ObjectMapper objectMapper;

    @Transactional
    public void send(Long userId, String type, String title, String body, Map<String, Object> data) {
        Notification notification = new Notification();
        notification.setUserId(userId);
        notification.setType(type);
        notification.setTitle(title);
        notification.setBody(body);
        notification.setData(toJson(data));
        notificationRepository.save(notification);
        try {
            pushSender.push(userId, title, body, data);
        } catch (Exception e) {
            // 推送失败不影响主流程
            log.warn("推送失败 userId={} type={}", userId, type, e);
        }
    }

    @Transactional(readOnly = true)
    public PageResult<NotificationResponse> page(Long userId, int page, int size) {
        Pageable pageable = PageRequest.of(Math.max(page - 1, 0), Math.min(size, 50));
        return PageResult.of(notificationRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable),
                NotificationResponse::from);
    }

    @Transactional
    public void markRead(Long userId, Long id) {
        Notification notification = notificationRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new BizException(ErrorCode.NOT_FOUND));
        if (notification.getReadAt() == null) {
            notification.setReadAt(LocalDateTime.now());
            notificationRepository.save(notification);
        }
    }

    @Transactional
    public int markAllRead(Long userId) {
        return notificationRepository.markAllRead(userId);
    }

    private String toJson(Map<String, Object> data) {
        try {
            return objectMapper.writeValueAsString(data == null ? Map.of() : data);
        } catch (Exception e) {
            return "{}";
        }
    }
}
