package com.repairhub.user.controller;

import com.repairhub.auth.security.SecurityUtils;
import com.repairhub.common.response.ApiResponse;
import com.repairhub.user.dto.CustomerProfileResponse;
import com.repairhub.user.dto.UpdateCustomerProfileRequest;
import com.repairhub.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "客户端-个人资料")
@RestController
@RequestMapping("/api/customer/profile")
@RequiredArgsConstructor
public class CustomerProfileController {

    private final UserService userService;

    @Operation(summary = "我的资料")
    @GetMapping
    public ApiResponse<CustomerProfileResponse> profile() {
        return ApiResponse.ok(userService.getProfile(SecurityUtils.currentUserId()));
    }

    @Operation(summary = "更新资料")
    @PutMapping
    public ApiResponse<CustomerProfileResponse> update(@Valid @RequestBody UpdateCustomerProfileRequest request) {
        return ApiResponse.ok(userService.updateProfile(SecurityUtils.currentUserId(), request));
    }
}
