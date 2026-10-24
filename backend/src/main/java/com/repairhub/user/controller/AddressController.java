package com.repairhub.user.controller;

import com.repairhub.auth.security.SecurityUtils;
import com.repairhub.common.response.ApiResponse;
import com.repairhub.user.dto.AddressRequest;
import com.repairhub.user.dto.AddressResponse;
import com.repairhub.user.service.AddressService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "客户端-地址管理")
@RestController
@RequestMapping("/api/customer/addresses")
@RequiredArgsConstructor
public class AddressController {

    private final AddressService addressService;

    @Operation(summary = "地址列表")
    @GetMapping
    public ApiResponse<List<AddressResponse>> list() {
        return ApiResponse.ok(addressService.list(SecurityUtils.currentUserId()));
    }

    @Operation(summary = "新增地址")
    @PostMapping
    public ApiResponse<AddressResponse> create(@Valid @RequestBody AddressRequest request) {
        return ApiResponse.ok(addressService.create(SecurityUtils.currentUserId(), request));
    }

    @Operation(summary = "更新地址")
    @PutMapping("/{id}")
    public ApiResponse<AddressResponse> update(@PathVariable Long id,
                                               @Valid @RequestBody AddressRequest request) {
        return ApiResponse.ok(addressService.update(SecurityUtils.currentUserId(), id, request));
    }

    @Operation(summary = "删除地址")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        addressService.delete(SecurityUtils.currentUserId(), id);
        return ApiResponse.ok();
    }
}
