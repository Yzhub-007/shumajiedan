package com.repairhub.order.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
public class CreateOrderRequest {

    @NotNull(message = "设备类型不能为空")
    private Long deviceCategoryId;

    private String deviceBrand;

    private String deviceModel;

    @NotNull(message = "故障描述不能为空")
    private String faultDesc;

    /** 图片/视频 URL 列表（先经 /api/upload/presign 直传 OSS） */
    private List<String> mediaUrls;

    @NotNull(message = "服务地址不能为空")
    private Long addressId;

    /** NORMAL / URGENT / CRITICAL，默认 NORMAL */
    private String urgency;

    private LocalDateTime expectTime;
}
