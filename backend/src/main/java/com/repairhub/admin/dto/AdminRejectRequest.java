package com.repairhub.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class AdminRejectRequest {

    @NotBlank(message = "拒绝原因不能为空")
    @Size(max = 500)
    private String reason;
}
