package com.repairhub.admin.controller;

import com.repairhub.admin.dto.AdminLoginRequest;
import com.repairhub.admin.service.AdminAuthService;
import com.repairhub.auth.dto.TokenResponse;
import com.repairhub.common.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "后台-认证")
@RestController
@RequestMapping("/admin/auth")
@RequiredArgsConstructor
public class AdminAuthController {

    private final AdminAuthService adminAuthService;

    @Operation(summary = "管理员登录（用户名密码）")
    @PostMapping("/login")
    public ApiResponse<TokenResponse> login(@Valid @RequestBody AdminLoginRequest request) {
        return ApiResponse.ok(adminAuthService.login(request));
    }
}
