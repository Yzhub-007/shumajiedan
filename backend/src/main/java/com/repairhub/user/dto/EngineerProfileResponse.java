package com.repairhub.user.dto;

import com.repairhub.common.util.JsonUtils;
import com.repairhub.user.entity.EngineerProfile;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class EngineerProfileResponse {

    private Long userId;
    private String realName;
    private String idCardNo;
    private String idCardFrontUrl;
    private String idCardBackUrl;
    private List<String> certUrls;
    private List<String> skillTags;
    private Integer serviceRadiusKm;
    private String verifyStatus;
    private String verifyStatusLabel;
    private String rejectReason;
    private BigDecimal ratingAvg;
    private Integer orderCount;
    private Boolean onlineStatus;
    private Double lastLng;
    private Double lastLat;
    private LocalDateTime lastLocationAt;
    private LocalDateTime createdAt;

    public static EngineerProfileResponse from(EngineerProfile profile) {
        return EngineerProfileResponse.builder()
                .userId(profile.getUserId())
                .realName(profile.getRealName())
                .idCardNo(mask(profile.getIdCardNo()))
                .idCardFrontUrl(profile.getIdCardFrontUrl())
                .idCardBackUrl(profile.getIdCardBackUrl())
                .certUrls(JsonUtils.readStringArray(profile.getCertUrls()))
                .skillTags(JsonUtils.readStringArray(profile.getSkillTags()))
                .serviceRadiusKm(profile.getServiceRadiusKm())
                .verifyStatus(profile.getVerifyStatus().name())
                .verifyStatusLabel(profile.getVerifyStatus().getLabel())
                .rejectReason(profile.getRejectReason())
                .ratingAvg(profile.getRatingAvg())
                .orderCount(profile.getOrderCount())
                .onlineStatus(profile.getOnlineStatus())
                .lastLng(profile.getLastLng())
                .lastLat(profile.getLastLat())
                .lastLocationAt(profile.getLastLocationAt())
                .createdAt(profile.getCreatedAt())
                .build();
    }

    /** 身份证脱敏展示（计划书 12 安全合规） */
    private static String mask(String idCardNo) {
        if (idCardNo == null || idCardNo.length() < 8) {
            return idCardNo;
        }
        return idCardNo.substring(0, 4) + "**********" + idCardNo.substring(idCardNo.length() - 4);
    }
}
