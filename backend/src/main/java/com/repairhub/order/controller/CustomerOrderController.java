package com.repairhub.order.controller;

import com.repairhub.auth.security.SecurityUtils;
import com.repairhub.auth.security.UserPrincipal;
import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.common.response.ApiResponse;
import com.repairhub.common.response.PageResult;
import com.repairhub.dispatch.service.DispatchService;
import com.repairhub.order.dto.CreateOrderRequest;
import com.repairhub.order.dto.EngineerLocationResponse;
import com.repairhub.order.dto.OrderDetailResponse;
import com.repairhub.order.dto.OrderResponse;
import com.repairhub.order.dto.ReasonRequest;
import com.repairhub.order.dto.ReviewRequest;
import com.repairhub.order.entity.Order;
import com.repairhub.order.repository.OrderRepository;
import com.repairhub.order.service.OrderActionService;
import com.repairhub.order.service.OrderService;
import com.repairhub.order.service.QuoteService;
import com.repairhub.order.service.ReviewService;
import com.repairhub.order.state.OrderAction;
import com.repairhub.user.entity.UserRole;
import com.repairhub.user.repository.EngineerProfileRepository;
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

import java.util.Map;

/**
 * 客户端工单接口（计划书 7.客户端）。
 */
@Tag(name = "客户端-工单")
@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class CustomerOrderController {

    private final OrderService orderService;
    private final OrderActionService orderActionService;
    private final QuoteService quoteService;
    private final ReviewService reviewService;
    private final OrderRepository orderRepository;
    private final EngineerProfileRepository engineerProfileRepository;
    private final DispatchService dispatchService;

    @Operation(summary = "发布工单")
    @PostMapping
    public ApiResponse<OrderResponse> create(@Valid @RequestBody CreateOrderRequest request) {
        return ApiResponse.ok(orderService.create(request, SecurityUtils.currentUserId()));
    }

    @Operation(summary = "我的工单（可按状态筛选）")
    @GetMapping
    public ApiResponse<PageResult<OrderResponse>> list(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        return ApiResponse.ok(orderService.pageCustomerOrders(SecurityUtils.currentUserId(), status, page, size));
    }

    @Operation(summary = "工单详情（状态流水/报价/报告/工程师信息）")
    @GetMapping("/{id}")
    public ApiResponse<OrderDetailResponse> detail(@PathVariable Long id) {
        UserPrincipal principal = SecurityUtils.current();
        return ApiResponse.ok(orderService.detail(id, principal.userId(),
                UserRole.valueOf(principal.role())));
    }

    @Operation(summary = "取消工单")
    @PostMapping("/{id}/cancel")
    public ApiResponse<Void> cancel(@PathVariable Long id, @Valid @RequestBody ReasonRequest request) {
        orderService.cancel(id, SecurityUtils.currentUserId(), request.getReason());
        return ApiResponse.ok();
    }

    @Operation(summary = "确认报价 → 进入维修中")
    @PostMapping("/{id}/quotes/{quoteId}/accept")
    public ApiResponse<Void> acceptQuote(@PathVariable Long id, @PathVariable Long quoteId) {
        quoteService.accept(id, quoteId, SecurityUtils.currentUserId());
        return ApiResponse.ok();
    }

    @Operation(summary = "拒绝报价（工程师可重新报价）")
    @PostMapping("/{id}/quotes/{quoteId}/reject")
    public ApiResponse<Void> rejectQuote(@PathVariable Long id, @PathVariable Long quoteId) {
        quoteService.reject(id, quoteId, SecurityUtils.currentUserId());
        return ApiResponse.ok();
    }

    @Operation(summary = "验收通过")
    @PostMapping("/{id}/confirm")
    public ApiResponse<Void> confirm(@PathVariable Long id) {
        orderActionService.apply(id, OrderAction.CONFIRM_FINISH, SecurityUtils.currentUserId(),
                UserRole.CUSTOMER, "验收通过");
        return ApiResponse.ok();
    }

    @Operation(summary = "验收不通过 → 退回返修")
    @PostMapping("/{id}/reject-finish")
    public ApiResponse<Void> rejectFinish(@PathVariable Long id, @Valid @RequestBody ReasonRequest request) {
        orderActionService.apply(id, OrderAction.REJECT_FINISH, SecurityUtils.currentUserId(),
                UserRole.CUSTOMER, request.getReason());
        return ApiResponse.ok();
    }

    @Operation(summary = "评价工程师")
    @PostMapping("/{id}/review")
    public ApiResponse<Void> review(@PathVariable Long id, @Valid @RequestBody ReviewRequest request) {
        reviewService.submit(id, SecurityUtils.currentUserId(), request);
        return ApiResponse.ok();
    }

    @Operation(summary = "工程师当前位置（前往中实时地图）")
    @GetMapping("/{id}/engineer-location")
    public ApiResponse<EngineerLocationResponse> engineerLocation(@PathVariable Long id) {
        Order order = requireOwnOrder(id);
        if (order.getEngineerId() == null) {
            return ApiResponse.ok(null);
        }
        return ApiResponse.ok(engineerProfileRepository.findById(order.getEngineerId())
                .map(profile -> EngineerLocationResponse.builder()
                        .engineerId(profile.getUserId())
                        .lng(profile.getLastLng())
                        .lat(profile.getLastLat())
                        .updatedAt(profile.getLastLocationAt())
                        .build())
                .orElse(null));
    }

    @Operation(summary = "附近在线工程师数（等待接单页展示）")
    @GetMapping("/{id}/nearby-count")
    public ApiResponse<Map<String, Long>> nearbyCount(@PathVariable Long id) {
        Order order = requireOwnOrder(id);
        return ApiResponse.ok(Map.of("count",
                dispatchService.nearbyEngineerCount(order.getLng(), order.getLat())));
    }

    private Order requireOwnOrder(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BizException(ErrorCode.ORDER_NOT_FOUND));
        if (!order.getCustomerId().equals(SecurityUtils.currentUserId())) {
            throw new BizException(ErrorCode.FORBIDDEN);
        }
        return order;
    }
}
