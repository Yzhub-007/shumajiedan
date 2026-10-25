package com.repairhub.admin.controller;

import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.common.response.ApiResponse;
import com.repairhub.common.response.PageResult;
import com.repairhub.user.entity.User;
import com.repairhub.user.entity.UserRole;
import com.repairhub.user.repository.UserRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 后台用户管理（计划书 3.3.3）。
 */
@Tag(name = "后台-用户管理")
@RestController
@RequestMapping("/admin/users")
@RequiredArgsConstructor
public class AdminUserController {

    private final UserRepository userRepository;

    @Operation(summary = "用户列表（按角色筛选，手机号脱敏）")
    @GetMapping
    public ApiResponse<PageResult<UserRow>> list(
            @RequestParam(required = false) String role,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        Pageable pageable = PageRequest.of(Math.max(page - 1, 0), Math.min(size, 100),
                Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<User> result = (role == null || role.isBlank())
                ? userRepository.findAll(pageable)
                : userRepository.findByRole(parseRole(role), pageable);
        return ApiResponse.ok(PageResult.of(result, UserRow::from));
    }

    @Operation(summary = "禁用账号")
    @PostMapping("/{id}/disable")
    public ApiResponse<Void> disable(@PathVariable Long id) {
        setStatus(id, "DISABLED");
        return ApiResponse.ok();
    }

    @Operation(summary = "启用账号")
    @PostMapping("/{id}/enable")
    public ApiResponse<Void> enable(@PathVariable Long id) {
        setStatus(id, "ACTIVE");
        return ApiResponse.ok();
    }

    private void setStatus(Long id, String status) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new BizException(ErrorCode.NOT_FOUND, "用户不存在"));
        user.setStatus(status);
        userRepository.save(user);
    }

    private UserRole parseRole(String role) {
        try {
            return UserRole.valueOf(role.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new BizException(ErrorCode.PARAM_ERROR, "非法角色: " + role);
        }
    }

    @Data
    @Builder
    public static class UserRow {
        private Long id;
        private String phone;
        private String nickname;
        private String role;
        private String status;
        private String createdAt;

        static UserRow from(User user) {
            String phone = user.getPhone();
            String masked = phone != null && phone.length() == 11
                    ? phone.substring(0, 3) + "****" + phone.substring(7)
                    : phone;
            return UserRow.builder()
                    .id(user.getId())
                    .phone(masked)
                    .nickname(user.getNickname())
                    .role(user.getRole() == null ? null : user.getRole().name())
                    .status(user.getStatus())
                    .createdAt(user.getCreatedAt() == null ? null : user.getCreatedAt().toString())
                    .build();
        }
    }
}
