package com.repairhub.order.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
public class QuoteRequest {

    @NotNull(message = "工时费不能为空")
    @DecimalMin(value = "0", message = "工时费不能为负数")
    private BigDecimal laborFee;

    @DecimalMin(value = "0", message = "配件费不能为负数")
    private BigDecimal partsFee;

    /** 配件明细描述列表 */
    private List<String> partsDetail;
}
