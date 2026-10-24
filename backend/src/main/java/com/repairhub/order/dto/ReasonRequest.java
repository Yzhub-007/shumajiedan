package com.repairhub.order.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 取消 / 验收退回 / 无法修复关闭 的原因。
 */
@Data
public class ReasonRequest {

    @NotBlank(message = "原因不能为空")
    @Size(max = 500, message = "原因最多 500 字")
    private String reason;
}
