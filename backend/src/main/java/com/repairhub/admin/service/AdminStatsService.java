package com.repairhub.admin.service;

import com.repairhub.order.entity.DeviceCategory;
import com.repairhub.order.enums.OrderStatus;
import com.repairhub.order.repository.DeviceCategoryRepository;
import com.repairhub.order.repository.OrderRepository;
import com.repairhub.user.entity.VerifyStatus;
import com.repairhub.user.repository.EngineerProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 后台统计概览（计划书 4.1.1 报表的简化版；趋势图/区域热力进 V1.1 报表看板）。
 */
@Service
@RequiredArgsConstructor
public class AdminStatsService {

    private final OrderRepository orderRepository;
    private final EngineerProfileRepository engineerProfileRepository;
    private final DeviceCategoryRepository deviceCategoryRepository;

    @Transactional(readOnly = true)
    public Map<String, Object> overview() {
        Map<String, Object> data = new LinkedHashMap<>();

        Map<String, Long> byStatus = new LinkedHashMap<>();
        for (OrderStatus status : OrderStatus.values()) {
            byStatus.put(status.name(), orderRepository.countByStatus(status));
        }
        data.put("ordersByStatus", byStatus);
        data.put("todayOrders", orderRepository.countByCreatedAtAfter(LocalDate.now().atStartOfDay()));

        List<DeviceCategory> categories = deviceCategoryRepository.findAllByOrderBySortAscIdAsc();
        data.put("deviceCategoryCount", categories.size());

        data.put("approvedEngineers", engineerProfileRepository.findByVerifyStatus(VerifyStatus.APPROVED).size());
        data.put("pendingVerify", engineerProfileRepository.findByVerifyStatus(VerifyStatus.PENDING).size());
        return data;
    }
}
