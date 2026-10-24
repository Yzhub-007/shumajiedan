package com.repairhub.order.controller;

import com.repairhub.common.response.ApiResponse;
import com.repairhub.order.dto.CategoryResponse;
import com.repairhub.order.service.DeviceCategoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "设备类型")
@RestController
@RequestMapping("/api/device-categories")
@RequiredArgsConstructor
public class DeviceCategoryController {

    private final DeviceCategoryService deviceCategoryService;

    @Operation(summary = "设备类型树（含基础价格）")
    @GetMapping
    public ApiResponse<List<CategoryResponse>> tree() {
        return ApiResponse.ok(deviceCategoryService.tree(true));
    }
}
