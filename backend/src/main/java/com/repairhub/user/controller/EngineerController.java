package com.repairhub.user.controller;

import com.repairhub.auth.security.SecurityUtils;
import com.repairhub.common.response.ApiResponse;
import com.repairhub.order.dto.EngineerStatsResponse;
import com.repairhub.order.service.EngineerOrderService;
import com.repairhub.user.dto.EngineerProfileResponse;
import com.repairhub.user.dto.EngineerVerifyRequest;
import com.repairhub.user.dto.LocationReportRequest;
import com.repairhub.user.dto.UpdateOnlineRequest;
import com.repairhub.user.service.EngineerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 工程师端：资质认证、上下线、位置上报、统计（计划书 7.工程师端）。
 */
@Tag(name = "工程师端-账号")
@RestController
@RequestMapping("/api/engineer")
@RequiredArgsConstructor
public class EngineerController {

    private final EngineerService engineerService;
    private final EngineerOrderService engineerOrderService;

    @Operation(summary = "提交资质认证")
    @PostMapping("/verify")
    public ApiResponse<EngineerProfileResponse> verify(@Valid @RequestBody EngineerVerifyRequest request) {
        return ApiResponse.ok(engineerService.submitVerify(SecurityUtils.currentUserId(), request));
    }

    @Operation(summary = "审核状态/我的资质")
    @GetMapping("/verify-status")
    public ApiResponse<EngineerProfileResponse> verifyStatus() {
        return ApiResponse.ok(engineerService.verifyStatus(SecurityUtils.currentUserId()));
    }

    @Operation(summary = "上线/下线（上线需携带坐标）")
    @PutMapping("/online")
    public ApiResponse<Void> online(@Valid @RequestBody UpdateOnlineRequest request) {
        engineerService.setOnline(SecurityUtils.currentUserId(),
                Boolean.TRUE.equals(request.getOnline()), request.getLng(), request.getLat());
        return ApiResponse.ok();
    }

    @Operation(summary = "位置上报（上线期间每 10~15 秒）")
    @PostMapping("/location")
    public ApiResponse<Void> location(@Valid @RequestBody LocationReportRequest request) {
        engineerService.reportLocation(SecurityUtils.currentUserId(),
                request.getLng(), request.getLat());
        return ApiResponse.ok();
    }

    @Operation(summary = "接单/收入统计")
    @GetMapping("/stats")
    public ApiResponse<EngineerStatsResponse> stats() {
        return ApiResponse.ok(engineerOrderService.stats(SecurityUtils.currentUserId()));
    }
}
