package com.repairhub.auth.controller;

import com.repairhub.auth.dto.LoginRequest;
import com.repairhub.auth.dto.RefreshTokenRequest;
import com.repairhub.auth.dto.SendSmsCodeRequest;
import com.repairhub.auth.dto.TokenResponse;
import com.repairhub.auth.service.AuthService;
import com.repairhub.common.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@Tag(name = "认证")
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @Operation(summary = "发送短信验证码")
    @PostMapping("/sms-code")
    public ApiResponse<Map<String, Object>> sendSmsCode(@Valid @RequestBody SendSmsCodeRequest request) {
        return ApiResponse.ok(authService.sendSmsCode(request.getPhone()));
    }

    @Operation(summary = "验证码登录（新用户自动注册）")
    @PostMapping("/login")
    public ApiResponse<TokenResponse> login(@Valid @RequestBody LoginRequest request) {
        return ApiResponse.ok(authService.login(request));
    }

    @Operation(summary = "刷新 token")
    @PostMapping("/refresh")
    public ApiResponse<TokenResponse> refresh(@Valid @RequestBody RefreshTokenRequest request) {
        return ApiResponse.ok(authService.refresh(request.getRefreshToken()));
    }
}
