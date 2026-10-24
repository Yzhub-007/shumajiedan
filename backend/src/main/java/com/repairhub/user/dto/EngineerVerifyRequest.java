package com.repairhub.user.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;

/**
 * 工程师资质提交（计划书 2.2.6）：身份证正反面 + 技能证书 + 擅长设备类型 + 服务半径。
 */
@Data
public class EngineerVerifyRequest {

    @NotBlank(message = "真实姓名不能为空")
    @Size(max = 50)
    private String realName;

    @NotBlank(message = "身份证号不能为空")
    @Size(max = 18, message = "身份证号格式不正确")
    private String idCardNo;

    @NotBlank(message = "身份证正面照不能为空")
    private String idCardFrontUrl;

    @NotBlank(message = "身份证反面照不能为空")
    private String idCardBackUrl;

    private List<String> certUrls;

    @Size(max = 20, message = "技能标签最多 20 个")
    private List<String> skillTags;

    @Min(value = 1, message = "服务半径至少 1 公里")
    @Max(value = 100, message = "服务半径最大 100 公里")
    private Integer serviceRadiusKm;
}
