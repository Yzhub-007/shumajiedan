package com.repairhub.order.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 到达签到请求：携带当前 GPS 坐标做距离校验（计划书 3.1.5）。
 */
@Data
public class ArriveRequest {

    @NotNull(message = "经度不能为空")
    private Double lng;

    @NotNull(message = "纬度不能为空")
    private Double lat;
}
