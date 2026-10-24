package com.repairhub.order.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import lombok.Data;

import java.util.List;

/**
 * 完工提交：维修报告 + 现场照片（计划书 3.1.7）。
 */
@Data
public class FinishOrderRequest {

    @NotBlank(message = "故障诊断不能为空")
    private String diagnosis;

    @NotBlank(message = "维修方案不能为空")
    private String solution;

    @NotEmpty(message = "维修前照片不能为空")
    private List<String> beforePhotos;

    @NotEmpty(message = "维修后照片不能为空")
    private List<String> afterPhotos;

    private List<String> partsReplaced;
}
