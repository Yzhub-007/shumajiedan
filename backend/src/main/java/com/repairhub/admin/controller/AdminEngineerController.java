package com.repairhub.admin.controller;

import com.repairhub.admin.dto.AdminRejectRequest;
import com.repairhub.admin.service.AdminOpLogService;
import com.repairhub.auth.security.SecurityUtils;
import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.common.response.ApiResponse;
import com.repairhub.common.response.PageResult;
import com.repairhub.user.dto.EngineerProfileResponse;
import com.repairhub.user.entity.EngineerProfile;
import com.repairhub.user.entity.VerifyStatus;
import com.repairhub.user.repository.EngineerProfileRepository;
import com.repairhub.user.service.EngineerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 后台工程师审核（计划书 2.1.7 / 2.3.2）。
 */
@Tag(name = "后台-工程师审核")
@RestController
@RequestMapping("/admin/engineers")
@RequiredArgsConstructor
public class AdminEngineerController {

    private final EngineerProfileRepository engineerProfileRepository;
    private final EngineerService engineerService;
    private final AdminOpLogService opLogService;

    @Operation(summary = "工程师列表（按审核状态筛选）")
    @GetMapping
    public ApiResponse<PageResult<EngineerProfileResponse>> list(
            @RequestParam(required = false) String verifyStatus,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        Pageable pageable = PageRequest.of(Math.max(page - 1, 0), Math.min(size, 100),
                Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<EngineerProfile> result = (verifyStatus == null || verifyStatus.isBlank())
                ? engineerProfileRepository.findAll(pageable)
                : engineerProfileRepository.findByVerifyStatus(parseStatus(verifyStatus), pageable);
        return ApiResponse.ok(PageResult.of(result, EngineerProfileResponse::from));
    }

    @Operation(summary = "审核通过")
    @PostMapping("/{userId}/approve")
    public ApiResponse<Void> approve(@PathVariable Long userId) {
        EngineerProfile profile = requireProfile(userId);
        profile.setVerifyStatus(VerifyStatus.APPROVED);
        profile.setRejectReason(null);
        engineerProfileRepository.save(profile);
        engineerService.notifyVerifyResult(userId, true, null);
        opLogService.record(SecurityUtils.currentUserId(), "ENGINEER_APPROVE",
                "engineer:" + userId, Map.of());
        return ApiResponse.ok();
    }

    @Operation(summary = "审核拒绝")
    @PostMapping("/{userId}/reject")
    public ApiResponse<Void> reject(@PathVariable Long userId, @Valid @RequestBody AdminRejectRequest request) {
        EngineerProfile profile = requireProfile(userId);
        profile.setVerifyStatus(VerifyStatus.REJECTED);
        profile.setRejectReason(request.getReason());
        engineerProfileRepository.save(profile);
        engineerService.notifyVerifyResult(userId, false, request.getReason());
        opLogService.record(SecurityUtils.currentUserId(), "ENGINEER_REJECT",
                "engineer:" + userId, Map.of("reason", request.getReason()));
        return ApiResponse.ok();
    }

    private EngineerProfile requireProfile(Long userId) {
        EngineerProfile profile = engineerProfileRepository.findById(userId)
                .orElseThrow(() -> new BizException(ErrorCode.NOT_FOUND, "工程师不存在"));
        if (profile.getVerifyStatus() == VerifyStatus.APPROVED) {
            throw new BizException(ErrorCode.CONFLICT, "该工程师已通过审核");
        }
        return profile;
    }

    private VerifyStatus parseStatus(String status) {
        try {
            return VerifyStatus.valueOf(status.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new BizException(ErrorCode.PARAM_ERROR, "非法的审核状态: " + status);
        }
    }
}
