package com.repairhub.order.controller;

import com.repairhub.auth.security.SecurityUtils;
import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.common.response.ApiResponse;
import com.repairhub.common.response.PageResult;
import com.repairhub.dispatch.service.GrabService;
import com.repairhub.order.dto.ArriveRequest;
import com.repairhub.order.dto.FinishOrderRequest;
import com.repairhub.order.dto.OrderResponse;
import com.repairhub.order.dto.PoolOrderResponse;
import com.repairhub.order.dto.QuoteRequest;
import com.repairhub.order.dto.ReasonRequest;
import com.repairhub.order.dto.QuoteResponse;
import com.repairhub.order.service.EngineerOrderService;
import com.repairhub.order.service.QuoteService;
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
 * 工程师端工单接口（计划书 7.工程师端）。
 */
@Tag(name = "工程师端-工单")
@RestController
@RequestMapping("/api/engineer/orders")
@RequiredArgsConstructor
public class EngineerOrderController {

    private final EngineerOrderService engineerOrderService;
    private final GrabService grabService;
    private final QuoteService quoteService;

    @Operation(summary = "可抢工单池（按距离排序）")
    @GetMapping("/pool")
    public ApiResponse<List<PoolOrderResponse>> pool(@RequestParam(defaultValue = "20") int limit) {
        return ApiResponse.ok(engineerOrderService.pool(SecurityUtils.currentUserId(), limit));
    }

    @Operation(summary = "我的工单")
    @GetMapping
    public ApiResponse<PageResult<OrderResponse>> myOrders(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        return ApiResponse.ok(engineerOrderService.myOrders(SecurityUtils.currentUserId(), status, page, size));
    }

    @Operation(summary = "抢单")
    @PostMapping("/{id}/grab")
    public ApiResponse<Void> grab(@PathVariable Long id) {
        grabService.grab(id, SecurityUtils.currentUserId());
        return ApiResponse.ok();
    }

    @Operation(summary = "出发")
    @PostMapping("/{id}/depart")
    public ApiResponse<Void> depart(@PathVariable Long id) {
        engineerOrderService.depart(id, SecurityUtils.currentUserId());
        return ApiResponse.ok();
    }

    @Operation(summary = "到达签到（GPS 距离校验）")
    @PostMapping("/{id}/arrive")
    public ApiResponse<Void> arrive(@PathVariable Long id, @Valid @RequestBody ArriveRequest request) {
        engineerOrderService.arrive(id, SecurityUtils.currentUserId(), request.getLng(), request.getLat());
        return ApiResponse.ok();
    }

    @Operation(summary = "提交报价")
    @PostMapping("/{id}/quote")
    public ApiResponse<QuoteResponse> quote(@PathVariable Long id, @Valid @RequestBody QuoteRequest request) {
        return ApiResponse.ok(quoteService.submit(id, SecurityUtils.currentUserId(), request));
    }

    @Operation(summary = "开始维修（无报价场景）")
    @PostMapping("/{id}/start-repair")
    public ApiResponse<Void> startRepair(@PathVariable Long id) {
        engineerOrderService.startRepair(id, SecurityUtils.currentUserId());
        return ApiResponse.ok();
    }

    @Operation(summary = "完工提交（维修报告 + 照片）")
    @PostMapping("/{id}/finish")
    public ApiResponse<Void> finish(@PathVariable Long id, @Valid @RequestBody FinishOrderRequest request) {
        engineerOrderService.finish(id, SecurityUtils.currentUserId(),
                request.getDiagnosis(), request.getSolution(),
                request.getBeforePhotos(), request.getAfterPhotos(), request.getPartsReplaced());
        return ApiResponse.ok();
    }

    @Operation(summary = "无法修复关闭")
    @PostMapping("/{id}/close")
    public ApiResponse<Void> close(@PathVariable Long id, @Valid @RequestBody ReasonRequest request) {
        engineerOrderService.closeUnresolved(id, SecurityUtils.currentUserId(), request.getReason());
        return ApiResponse.ok();
    }
}
