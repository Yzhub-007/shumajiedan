package com.repairhub.admin.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class AssignEngineerRequest {

    @NotNull(message = "工程师不能为空")
    private Long engineerId;
}
