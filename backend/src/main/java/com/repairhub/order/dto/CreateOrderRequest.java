package com.repairhub.order.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
public class CreateOrderRequest {

    /** 选中字典设备类型时传；与 deviceCategoryInput 二选一 */
    private Long deviceCategoryId;

    /** 手动输入的设备类型文本，与 deviceCategoryId 二选一 */
    @Size(max = 50, message = "设备类型不能超过50个字符")
    private String deviceCategoryInput;

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
