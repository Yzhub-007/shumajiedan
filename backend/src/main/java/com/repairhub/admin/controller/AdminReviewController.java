package com.repairhub.admin.controller;

import com.repairhub.common.response.ApiResponse;
import com.repairhub.common.response.PageResult;
import com.repairhub.order.entity.Review;
import com.repairhub.order.repository.ReviewRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 后台评价管理（计划书 3.3.3）。纠纷处理时据此核查双方评价。
 */
@Tag(name = "后台-评价管理")
@RestController
@RequestMapping("/admin/reviews")
@RequiredArgsConstructor
public class AdminReviewController {

    private final ReviewRepository reviewRepository;

    @Operation(summary = "评价列表")
    @GetMapping
    public ApiResponse<PageResult<Map<String, Object>>> list(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        Pageable pageable = PageRequest.of(Math.max(page - 1, 0), Math.min(size, 100),
                Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Review> result = reviewRepository.findAll(pageable);
        return ApiResponse.ok(PageResult.of(result, review -> Map.of(
                "id", review.getId(),
                "orderId", review.getOrderId(),
                "fromUserId", review.getFromUserId(),
                "toUserId", review.getToUserId(),
                "score", review.getScore(),
                "content", review.getContent() == null ? "" : review.getContent(),
                "createdAt", review.getCreatedAt() == null ? "" : review.getCreatedAt().toString())));
    }
}
