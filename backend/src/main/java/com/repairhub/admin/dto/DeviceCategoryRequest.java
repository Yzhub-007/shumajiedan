package com.repairhub.admin.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 设备类型与价格配置（计划书 2.3.3 / 2.5 价格体系）。
 */
@Data
public class DeviceCategoryRequest {

    @NotBlank(message = "名称不能为空")
    @Size(max = 50)
    private String name;

    private Long parentId;

    @DecimalMin(value = "0", message = "基础费不能为负数")
    private BigDecimal baseFee;

    @DecimalMin(value = "0", message = "上门费不能为负数")
    private BigDecimal visitFee;

    private Integer sort;

    private Boolean enabled;
}
