package com.repairhub.order.dto;

import com.repairhub.order.entity.DeviceCategory;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

/**
 * 设备类型树（两级）。baseFee + visitFee 组成基础价格体系（计划书 2.5）。
 */
@Data
@Builder
public class CategoryResponse {

    private Long id;
    private Long parentId;
    private String name;
    private BigDecimal baseFee;
    private BigDecimal visitFee;
    private Integer sort;
    private Boolean enabled;
    private List<CategoryResponse> children;

    public static CategoryResponse from(DeviceCategory category) {
        return CategoryResponse.builder()
                .id(category.getId())
                .parentId(category.getParentId())
                .name(category.getName())
                .baseFee(category.getBaseFee())
                .visitFee(category.getVisitFee())
                .sort(category.getSort())
                .enabled(category.getEnabled())
                .build();
    }
}
