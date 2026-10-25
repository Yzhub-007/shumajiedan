package com.repairhub.admin.controller;

import com.repairhub.admin.service.AdminOpLogService;
import com.repairhub.auth.security.SecurityUtils;
import com.repairhub.common.response.ApiResponse;
import com.repairhub.common.response.PageResult;
import com.repairhub.payment.entity.Withdrawal;
import com.repairhub.payment.service.WalletService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 后台提现审核（计划书 3.2 / 2.5 财务）。仅超级管理员可操作（RBAC 2.1.8）。
 */
@Tag(name = "后台-提现审核")
@RestController
@RequestMapping("/admin/withdrawals")
@RequiredArgsConstructor
@PreAuthorize("hasRole('SUPER_ADMIN')")
public class AdminWithdrawalController {

    private final WalletService walletService;
    private final AdminOpLogService opLogService;

    @Operation(summary = "提现申请列表（按状态筛选）")
    @GetMapping
    public ApiResponse<PageResult<Withdrawal>> list(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        Page<Withdrawal> result = walletService.page(status, page, size);
        return ApiResponse.ok(PageResult.of(result, w -> w));
    }

    @Operation(summary = "审核通过（打款渠道接入见 TODO(V1.1)）")
    @PostMapping("/{id}/approve")
    public ApiResponse<Void> approve(@PathVariable Long id) {
        walletService.review(id, true, SecurityUtils.currentUserId(), null);
        opLogService.record(SecurityUtils.currentUserId(), "WITHDRAWAL_APPROVE",
                "withdrawal:" + id, Map.of());
        return ApiResponse.ok();
    }

    @Operation(summary = "审核拒绝（金额退回余额）")
    @PostMapping("/{id}/reject")
    public ApiResponse<Void> reject(@PathVariable Long id, @Valid @RequestBody RejectRequest request) {
        walletService.review(id, false, SecurityUtils.currentUserId(), request.getReason());
        opLogService.record(SecurityUtils.currentUserId(), "WITHDRAWAL_REJECT",
                "withdrawal:" + id, Map.of("reason", request.getReason()));
        return ApiResponse.ok();
    }

    @Data
    @lombok.NoArgsConstructor
    public static class RejectRequest {
        @jakarta.validation.constraints.NotBlank(message = "拒绝原因不能为空")
        private String reason;
    }
}
