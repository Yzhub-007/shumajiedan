package com.repairhub.payment.controller;

import com.repairhub.auth.security.SecurityUtils;
import com.repairhub.common.response.ApiResponse;
import com.repairhub.payment.entity.Wallet;
import com.repairhub.payment.entity.Withdrawal;
import com.repairhub.payment.service.WalletService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * 工程师钱包与提现（计划书 3.2 / 2.4 查看收入、提现）。
 */
@Tag(name = "工程师端-钱包")
@RestController
@RequestMapping("/api/engineer")
@RequiredArgsConstructor
public class EngineerWalletController {

    private final WalletService walletService;

    @Operation(summary = "我的钱包")
    @GetMapping("/wallet")
    public ApiResponse<Wallet> wallet() {
        return ApiResponse.ok(walletService.getOrCreate(SecurityUtils.currentUserId()));
    }

    @Operation(summary = "我的提现记录")
    @GetMapping("/withdrawals")
    public ApiResponse<List<Withdrawal>> myWithdrawals() {
        return ApiResponse.ok(walletService.myWithdrawals(SecurityUtils.currentUserId()));
    }

    @Operation(summary = "申请提现")
    @PostMapping("/withdrawals")
    public ApiResponse<Withdrawal> apply(@Valid @RequestBody WithdrawalRequest request) {
        return ApiResponse.ok(walletService.applyWithdrawal(SecurityUtils.currentUserId(),
                request.getAmount(), Map.of("account", request.getAccount())));
    }

    @Data
    public static class WithdrawalRequest {
        @NotNull(message = "提现金额不能为空")
        @DecimalMin(value = "0.01", message = "提现金额不合法")
        private BigDecimal amount;

        /** 收款账号说明（支付宝账号/银行卡号等） */
        @NotNull(message = "收款账户不能为空")
        private String account;
    }
}
