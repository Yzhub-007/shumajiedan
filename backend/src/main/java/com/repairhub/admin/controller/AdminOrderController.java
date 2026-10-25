package com.repairhub.admin.controller;

import com.repairhub.admin.dto.AssignEngineerRequest;
import com.repairhub.admin.service.AdminOrderService;
import com.repairhub.auth.security.SecurityUtils;
import com.repairhub.common.response.ApiResponse;
import com.repairhub.common.response.PageResult;
import com.repairhub.dispatch.service.DispatchService;
import com.repairhub.order.dto.OrderResponse;
import com.repairhub.order.dto.ReasonRequest;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 后台工单监控与人工干预（计划书 2.3.1 / 3.3.1）。
 */
@Tag(name = "后台-工单管理")
@RestController
@RequestMapping("/admin/orders")
@RequiredArgsConstructor
public class AdminOrderController {

    private final AdminOrderService adminOrderService;
    private final DispatchService dispatchService;

    @Operation(summary = "工单列表（订单号搜索 / 状态筛选）")
    @GetMapping
    public ApiResponse<PageResult<OrderResponse>> list(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        return ApiResponse.ok(adminOrderService.page(status, keyword, page, size));
    }

    @Operation(summary = "附近在线工程师候选人（指派/改派选人用）")
    @GetMapping("/{id}/nearby-engineers")
    public ApiResponse<List<DispatchService.NearbyEngineerView>> nearbyEngineers(@PathVariable Long id) {
        return ApiResponse.ok(dispatchService.listNearbyForOrder(id));
    }

    @Operation(summary = "指派工程师")
    @PostMapping("/{id}/assign")
    public ApiResponse<Void> assign(@PathVariable Long id,
                                    @Valid @RequestBody AssignEngineerRequest request) {
        adminOrderService.assign(id, request.getEngineerId(), SecurityUtils.currentUserId());
        return ApiResponse.ok();
    }

    @Operation(summary = "改派工程师")
    @PostMapping("/{id}/reassign")
    public ApiResponse<Void> reassign(@PathVariable Long id,
                                      @Valid @RequestBody AssignEngineerRequest request) {
        adminOrderService.reassign(id, request.getEngineerId(), SecurityUtils.currentUserId());
        return ApiResponse.ok();
    }

    @Operation(summary = "关闭工单")
    @PostMapping("/{id}/close")
    public ApiResponse<Void> close(@PathVariable Long id, @Valid @RequestBody ReasonRequest request) {
        adminOrderService.close(id, request.getReason(), SecurityUtils.currentUserId());
        return ApiResponse.ok();
    }
}
