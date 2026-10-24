package com.repairhub.user.dto;

import com.repairhub.user.entity.CustomerProfile;
import com.repairhub.user.entity.User;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CustomerProfileResponse {

    private Long userId;
    private String phone;
    private String nickname;
    private String companyName;
    private String contactName;
    private String industry;

    public static CustomerProfileResponse from(User user, CustomerProfile profile) {
        return CustomerProfileResponse.builder()
                .userId(user.getId())
                .phone(user.getPhone())
                .nickname(user.getNickname())
                .companyName(profile == null ? null : profile.getCompanyName())
                .contactName(profile == null ? null : profile.getContactName())
                .industry(profile == null ? null : profile.getIndustry())
                .build();
    }
}
