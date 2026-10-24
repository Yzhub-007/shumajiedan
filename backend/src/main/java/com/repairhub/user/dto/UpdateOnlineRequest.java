package com.repairhub.user.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 工程师上线/下线开关（上线需携带当前坐标写入 Redis GEO）。
 */
@Data
public class UpdateOnlineRequest {

    @NotNull(message = "上线状态不能为空")
    private Boolean online;

    private Double lng;

    private Double lat;
}
