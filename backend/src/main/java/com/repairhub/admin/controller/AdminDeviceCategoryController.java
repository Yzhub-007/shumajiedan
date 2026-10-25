package com.repairhub.admin.controller;

import com.repairhub.admin.dto.DeviceCategoryRequest;
import com.repairhub.common.response.ApiResponse;
import com.repairhub.order.dto.CategoryResponse;
import com.repairhub.order.entity.DeviceCategory;
import com.repairhub.order.repository.DeviceCategoryRepository;
import com.repairhub.order.service.DeviceCategoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 设备类型与价格配置（计划书 2.3.3）。
 */
@Tag(name = "后台-设备类型配置")
@RestController
@RequestMapping("/admin/device-categories")
@RequiredArgsConstructor
public class AdminDeviceCategoryController {

    private final DeviceCategoryRepository deviceCategoryRepository;
    private final DeviceCategoryService deviceCategoryService;

    @Operation(summary = "设备类型树（含停用项）")
    @GetMapping
    public ApiResponse<List<CategoryResponse>> tree() {
        return ApiResponse.ok(deviceCategoryService.tree(false));
    }

    @Operation(summary = "新增设备类型（仅超级管理员）")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    @PostMapping
    public ApiResponse<CategoryResponse> create(@Valid @RequestBody DeviceCategoryRequest request) {
        DeviceCategory category = new DeviceCategory();
        apply(category, request);
        return ApiResponse.ok(CategoryResponse.from(deviceCategoryRepository.save(category)));
    }

    @Operation(summary = "更新设备类型/价格（仅超级管理员）")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    @PutMapping("/{id}")
    public ApiResponse<CategoryResponse> update(@PathVariable Long id,
                                                @Valid @RequestBody DeviceCategoryRequest request) {
        DeviceCategory category = deviceCategoryRepository.findById(id).orElseThrow();
        apply(category, request);
        return ApiResponse.ok(CategoryResponse.from(deviceCategoryRepository.save(category)));
    }

    @Operation(summary = "停用（软删除，仅超级管理员）")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> disable(@PathVariable Long id) {
        DeviceCategory category = deviceCategoryRepository.findById(id).orElseThrow();
        category.setEnabled(false);
        deviceCategoryRepository.save(category);
        return ApiResponse.ok();
    }

    private void apply(DeviceCategory category, DeviceCategoryRequest request) {
        category.setName(request.getName());
        category.setParentId(request.getParentId());
        if (request.getBaseFee() != null) {
            category.setBaseFee(request.getBaseFee());
        }
        if (request.getVisitFee() != null) {
            category.setVisitFee(request.getVisitFee());
        }
        if (request.getSort() != null) {
            category.setSort(request.getSort());
        }
        if (request.getEnabled() != null) {
            category.setEnabled(request.getEnabled());
        }
    }
}
