package com.repairhub.order.service;

import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.common.util.JsonUtils;
import com.repairhub.notify.service.NotificationService;
import com.repairhub.order.dto.ReviewRequest;
import com.repairhub.order.entity.Order;
import com.repairhub.order.entity.Review;
import com.repairhub.order.repository.OrderRepository;
import com.repairhub.order.repository.ReviewRepository;
import com.repairhub.order.state.OrderAction;
import com.repairhub.user.entity.UserRole;
import com.repairhub.user.repository.EngineerProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Map;

/**
 * 双向评价 + 工程师评分聚合（计划书 3.1.9）。
 */
@Service
@RequiredArgsConstructor
public class ReviewService {

    private final OrderRepository orderRepository;
    private final ReviewRepository reviewRepository;
    private final EngineerProfileRepository engineerProfileRepository;
    private final OrderActionService orderActionService;
    private final NotificationService notificationService;

    @Transactional
    public void submit(Long orderId, Long fromUserId, ReviewRequest request) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BizException(ErrorCode.ORDER_NOT_FOUND));

        boolean fromCustomer = order.getCustomerId().equals(fromUserId);
        Long toUserId = fromCustomer ? order.getEngineerId() : order.getCustomerId();
        if (toUserId == null) {
            throw new BizException(ErrorCode.CONFLICT, "该工单无可评价对象");
        }
        if (reviewRepository.existsByOrderIdAndFromUserId(orderId, fromUserId)) {
            throw new BizException(ErrorCode.CONFLICT, "您已评价过该工单");
        }

        UserRole role = fromCustomer ? UserRole.CUSTOMER : UserRole.ENGINEER;
        orderActionService.apply(orderId, OrderAction.REVIEW, fromUserId, role, "评价");

        Review review = new Review();
        review.setOrderId(orderId);
        review.setFromUserId(fromUserId);
        review.setToUserId(toUserId);
        review.setScore(request.getScore());
        review.setTags(JsonUtils.write(request.getTags()));
        review.setContent(request.getContent());
        reviewRepository.save(review);

        notificationService.send(toUserId, "NEW_REVIEW", "收到新的评价",
                "工单 " + order.getOrderNo() + " 收到 " + request.getScore() + " 星评价",
                Map.of("orderId", orderId));

        if (!fromCustomer) {
            return;
        }
        // 客户评工程师 → 聚合评分（order_count 由完工时更新，此处仅评分）
        Double avg = reviewRepository.avgScoreByToUserId(toUserId);
        engineerProfileRepository.findById(toUserId).ifPresent(profile -> {
            profile.setRatingAvg(BigDecimal.valueOf(avg).setScale(2, RoundingMode.HALF_UP));
            engineerProfileRepository.save(profile);
        });
    }
}
