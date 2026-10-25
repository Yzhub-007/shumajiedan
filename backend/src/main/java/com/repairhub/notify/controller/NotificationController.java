package com.repairhub.notify.controller;

import com.repairhub.auth.security.SecurityUtils;
import com.repairhub.common.response.ApiResponse;
import com.repairhub.common.response.PageResult;
import com.repairhub.notify.dto.NotificationResponse;
import com.repairhub.notify.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "通知中心")
@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @Operation(summary = "通知列表")
    @GetMapping
    public ApiResponse<PageResult<NotificationResponse>> list(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.ok(notificationService.page(SecurityUtils.currentUserId(), page, size));
    }

    @Operation(summary = "标记已读")
    @PostMapping("/{id}/read")
    public ApiResponse<Void> read(@PathVariable Long id) {
        notificationService.markRead(SecurityUtils.currentUserId(), id);
        return ApiResponse.ok();
    }

    @Operation(summary = "全部标记已读")
    @PostMapping("/read-all")
    public ApiResponse<Void> readAll() {
        notificationService.markAllRead(SecurityUtils.currentUserId());
        return ApiResponse.ok();
    }
}
