package com.repairhub.user.dto;

import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdateCustomerProfileRequest {

    @Size(max = 50, message = "昵称最多 50 字")
    private String nickname;

    @Size(max = 100, message = "企业名称最多 100 字")
    private String companyName;

    @Size(max = 50, message = "联系人最多 50 字")
    private String contactName;

    @Size(max = 50, message = "行业最多 50 字")
    private String industry;
}
