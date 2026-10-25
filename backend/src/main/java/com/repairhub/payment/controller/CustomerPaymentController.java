package com.repairhub.payment.controller;

import com.repairhub.auth.security.SecurityUtils;
import com.repairhub.common.response.ApiResponse;
import com.repairhub.payment.service.PaymentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 客户端支付（计划书 3.2）。app.order.payment-enabled=true 时，验收通过进入待支付，
 * 客户调用本接口完成支付（当前 MOCK 渠道）。
 */
@Tag(name = "客户端-支付")
@RestController
@RequiredArgsConstructor
public class CustomerPaymentController {

    private final PaymentService paymentService;

    @Operation(summary = "支付工单（MOCK 渠道，V1.1 接微信/支付宝）")
    @PostMapping("/api/orders/{id}/pay")
    public ApiResponse<Map<String, Object>> pay(@PathVariable Long id,
                                                @RequestBody(required = false) Map<String, String> body) {
        String channel = body == null ? "MOCK" : body.getOrDefault("channel", "MOCK");
        return ApiResponse.ok(paymentService.payOrder(id, SecurityUtils.currentUserId(), channel));
    }
}
