package com.repairhub.admin.service;

import com.repairhub.admin.dto.AdminLoginRequest;
import com.repairhub.admin.entity.Admin;
import com.repairhub.admin.repository.AdminRepository;
import com.repairhub.auth.dto.TokenResponse;
import com.repairhub.auth.security.JwtTokenProvider;
import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.user.entity.UserRole;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

/**
 * 后台管理员登录（计划书 2.1.8）。默认账号 admin/admin123（Flyway 种子数据，上线前改密）。
 */
@Service
@RequiredArgsConstructor
public class AdminAuthService {

    private final AdminRepository adminRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;

    public TokenResponse login(AdminLoginRequest request) {
        Admin admin = adminRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new BizException(ErrorCode.UNAUTHORIZED, "用户名或密码错误"));
        if (!"ACTIVE".equals(admin.getStatus())) {
            throw new BizException(ErrorCode.UNAUTHORIZED, "账号已被禁用");
        }
        if (!passwordEncoder.matches(request.getPassword(), admin.getPasswordHash())) {
            throw new BizException(ErrorCode.UNAUTHORIZED, "用户名或密码错误");
        }
        String access = tokenProvider.generateAccessToken(admin.getId(), admin.getUsername(), UserRole.ADMIN,
                java.util.Map.of("adminRole", admin.getRole()));
        String refresh = tokenProvider.generateRefreshToken(admin.getId(), admin.getUsername(), UserRole.ADMIN);
        return new TokenResponse(access, refresh, admin.getId(), UserRole.ADMIN.name(), false, admin.getRole());
    }
}
