package com.repairhub.admin.service;

import com.repairhub.order.entity.DeviceCategory;
import com.repairhub.order.entity.Order;
import com.repairhub.order.enums.OrderStatus;
import com.repairhub.order.repository.DeviceCategoryRepository;
import com.repairhub.order.repository.OrderRepository;
import com.repairhub.order.repository.ReviewRepository;
import com.repairhub.user.entity.EngineerProfile;
import com.repairhub.user.entity.VerifyStatus;
import com.repairhub.user.repository.EngineerProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 后台统计报表（计划书 4.1.1）：
 * 各状态分布、近 14 日订单量趋势、平均接单时长、完成率、平均评分、工程师接单排行。
 * 区域热力图与更多维度进 V1.1 报表看板。
 */
@Service
@RequiredArgsConstructor
public class AdminStatsService {

    private final OrderRepository orderRepository;
    private final ReviewRepository reviewRepository;
    private final EngineerProfileRepository engineerProfileRepository;
    private final DeviceCategoryRepository deviceCategoryRepository;

    @Transactional(readOnly = true)
    public Map<String, Object> overview() {
        Map<String, Object> data = new LinkedHashMap<>();

        // 状态分布
        Map<String, Long> byStatus = new LinkedHashMap<>();
        for (OrderStatus status : OrderStatus.values()) {
            byStatus.put(status.name(), orderRepository.countByStatus(status));
        }
        data.put("ordersByStatus", byStatus);
        data.put("todayOrders", orderRepository.countByCreatedAtAfter(LocalDate.now().atStartOfDay()));
        data.put("totalOrders", orderRepository.count());

        // 近 14 日订单量趋势
        LocalDateTime trendStart = LocalDate.now().minusDays(13).atStartOfDay();
        Map<LocalDate, Long> byDay = orderRepository.findByCreatedAtAfter(trendStart).stream()
                .collect(Collectors.groupingBy(o -> o.getCreatedAt().toLocalDate(), Collectors.counting()));
        List<Map<String, Object>> trend = new ArrayList<>();
        for (int i = 0; i < 14; i++) {
            LocalDate day = LocalDate.now().minusDays(13 - i);
            trend.add(Map.of("date", day.toString(), "count", byDay.getOrDefault(day, 0L)));
        }
        data.put("trend", trend);

        // 平均接单时长（近 30 天已接单工单：created → accepted）
        List<Order> recent = orderRepository.findByCreatedAtAfter(LocalDate.now().minusDays(30).atStartOfDay());
        double avgAccept = recent.stream()
                .filter(o -> o.getAcceptedAt() != null)
                .mapToLong(o -> Duration.between(o.getCreatedAt(), o.getAcceptedAt()).toMinutes())
                .average().orElse(0);
        data.put("avgAcceptMinutes", BigDecimal.valueOf(avgAccept).setScale(1, RoundingMode.HALF_UP));

        // 完成率 =（已完成 + 已评价）/ 全部
        long done = byStatus.getOrDefault(OrderStatus.COMPLETED.name(), 0L)
                + byStatus.getOrDefault(OrderStatus.REVIEWED.name(), 0L);
        long total = orderRepository.count();
        data.put("completionRate", total == 0 ? 0
                : BigDecimal.valueOf(done * 100.0 / total).setScale(1, RoundingMode.HALF_UP));

        // 平台平均评分
        Double avgScore = reviewRepository.avgScore();
        data.put("avgRating", avgScore == null ? null
                : BigDecimal.valueOf(avgScore).setScale(2, RoundingMode.HALF_UP));

        // 工程师接单排行 Top10
        List<Map<String, Object>> ranking = engineerProfileRepository.findTop10ByOrderByOrderCountDesc()
                .stream()
                .map(p -> {
                    Map<String, Object> row = new LinkedHashMap<String, Object>();
                    row.put("userId", p.getUserId());
                    row.put("realName", p.getRealName());
                    row.put("orderCount", p.getOrderCount());
                    row.put("ratingAvg", p.getRatingAvg());
                    return row;
                })
                .collect(Collectors.toList());
        data.put("engineerRanking", ranking);

        List<DeviceCategory> categories = deviceCategoryRepository.findAllByOrderBySortAscIdAsc();
        data.put("deviceCategoryCount", categories.size());
        data.put("approvedEngineers", engineerProfileRepository.findByVerifyStatus(VerifyStatus.APPROVED).size());
        data.put("pendingVerify", engineerProfileRepository.findByVerifyStatus(VerifyStatus.PENDING).size());
        return data;
    }
}
