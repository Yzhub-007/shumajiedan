package com.repairhub.user.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class AddressRequest {

    @Size(max = 50, message = "地址标签最多 50 字")
    private String label;

    private String province;

    private String city;

    private String district;

    @NotBlank(message = "详细地址不能为空")
    @Size(max = 200, message = "详细地址最多 200 字")
    private String detail;

    @NotNull(message = "经度不能为空")
    private Double lng;

    @NotNull(message = "纬度不能为空")
    private Double lat;

    private Boolean isDefault;
}
