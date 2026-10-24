package com.repairhub.user.service;

import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.common.util.JsonUtils;
import com.repairhub.dispatch.service.EngineerLocationService;
import com.repairhub.notify.service.NotificationService;
import com.repairhub.user.dto.EngineerProfileResponse;
import com.repairhub.user.dto.EngineerVerifyRequest;
import com.repairhub.user.entity.EngineerProfile;
import com.repairhub.user.entity.VerifyStatus;
import com.repairhub.user.repository.EngineerProfileRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * 工程师资质与接单状态（计划书 2.1.7 / 3.1.1）。
 * 位置上报同时写 Redis GEO（实时派单）与 DB（离线统计），DB 写入节流见 TODO。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class EngineerService {

    private final EngineerProfileRepository engineerProfileRepository;
    private final EngineerLocationService engineerLocationService;
    private final NotificationService notificationService;

    @Transactional
    public EngineerProfileResponse submitVerify(Long userId, EngineerVerifyRequest request) {
        EngineerProfile profile = engineerProfileRepository.findById(userId)
                .orElseGet(() -> {
                    EngineerProfile created = new EngineerProfile();
                    created.setUserId(userId);
                    return created;
                });
        profile.setRealName(request.getRealName());
        profile.setIdCardNo(request.getIdCardNo());
        profile.setIdCardFrontUrl(request.getIdCardFrontUrl());
        profile.setIdCardBackUrl(request.getIdCardBackUrl());
        profile.setCertUrls(JsonUtils.write(request.getCertUrls()));
        profile.setSkillTags(JsonUtils.write(request.getSkillTags()));
        if (request.getServiceRadiusKm() != null) {
            profile.setServiceRadiusKm(request.getServiceRadiusKm());
        }
        profile.setVerifyStatus(VerifyStatus.PENDING);
        profile.setRejectReason(null);
        return EngineerProfileResponse.from(engineerProfileRepository.save(profile));
    }

    @Transactional
    public EngineerProfileResponse verifyStatus(Long userId) {
        EngineerProfile profile = engineerProfileRepository.findById(userId)
                .orElseGet(() -> {
                    EngineerProfile created = new EngineerProfile();
                    created.setUserId(userId);
                    return engineerProfileRepository.save(created);
                });
        return EngineerProfileResponse.from(profile);
    }

    @Transactional
    public EngineerProfile requireProfile(Long userId) {
        EngineerProfile profile = engineerProfileRepository.findById(userId)
                .orElseThrow(() -> new BizException(ErrorCode.FORBIDDEN, "请先完成工程师资质认证"));
        if (profile.getVerifyStatus() != VerifyStatus.APPROVED) {
            throw new BizException(ErrorCode.ENGINEER_NOT_APPROVED);
        }
        return profile;
    }

    /** 上线/下线：上线要求已通过认证，并把位置写入 Redis GEO */
    @Transactional
    public void setOnline(Long userId, boolean online, Double lng, Double lat) {
        EngineerProfile profile = requireProfile(userId);
        profile.setOnlineStatus(online);
        if (online) {
            if (lng == null || lat == null) {
                throw new BizException(ErrorCode.PARAM_ERROR, "上线时必须携带当前坐标");
            }
            profile.setLastLng(lng);
            profile.setLastLat(lat);
            profile.setLastLocationAt(LocalDateTime.now());
            engineerProfileRepository.save(profile);
            engineerLocationService.online(userId, lng, lat);
        } else {
            engineerProfileRepository.save(profile);
            engineerLocationService.offline(userId);
        }
    }

    /** 位置上报：GEO 必写；DB 节流写（TODO(3.1.1) 60s 一次，避免高频更新） */
    @Transactional
    public void reportLocation(Long userId, double lng, double lat) {
        EngineerProfile profile = requireProfile(userId);
        if (!Boolean.TRUE.equals(profile.getOnlineStatus())) {
            return;
        }
        engineerLocationService.online(userId, lng, lat);
        profile.setLastLng(lng);
        profile.setLastLat(lat);
        profile.setLastLocationAt(LocalDateTime.now());
        engineerProfileRepository.save(profile);
    }

    /** 后台审核结果通知（admin 模块调用） */
    public void notifyVerifyResult(Long engineerId, boolean approved, String reason) {
        if (approved) {
            notificationService.send(engineerId, "VERIFY_RESULT", "资质审核通过",
                    "恭喜！您的工程师资质已通过审核，可以上线接单了", Map.of());
        } else {
            notificationService.send(engineerId, "VERIFY_RESULT", "资质审核未通过",
                    "原因：" + reason + "，请补充材料后重新提交", Map.of());
        }
    }
}
