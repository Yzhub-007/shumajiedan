package com.repairhub.auth.service;

import com.repairhub.auth.dto.LoginRequest;
import com.repairhub.auth.dto.TokenResponse;
import com.repairhub.auth.security.JwtTokenProvider;
import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.user.entity.User;
import com.repairhub.user.entity.UserRole;
import com.repairhub.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

/**
 * 验证码登录 + 注册 + JWT 刷新（计划书 2.1.1 / API 7.认证）。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final SmsCodeService smsCodeService;
    private final JwtTokenProvider tokenProvider;

    @Value("${app.sms.mock:true}")
    private boolean smsMock;

    public Map<String, Object> sendSmsCode(String phone) {
        String code = smsCodeService.sendCode(phone);
        Map<String, Object> data = new HashMap<>();
        if (smsMock) {
            // 仅开发环境把验证码返回给前端，生产必须移除
            data.put("devCode", code);
        }
        return data;
    }

    @Transactional
    public TokenResponse login(LoginRequest request) {
        smsCodeService.verify(request.getPhone(), request.getCode());
        boolean isNew = !userRepository.existsByPhone(request.getPhone());
        User user = userRepository.findByPhone(request.getPhone()).orElseGet(() -> register(request));
        if ("DISABLED".equals(user.getStatus())) {
            throw new BizException(ErrorCode.USER_DISABLED);
        }
        return issue(user, isNew);
    }

    public TokenResponse refresh(String refreshToken) {
        JwtTokenProvider.ParsedToken parsed;
        try {
            parsed = tokenProvider.parse(refreshToken);
        } catch (io.jsonwebtoken.JwtException e) {
            throw new BizException(ErrorCode.UNAUTHORIZED, "refreshToken 无效或已过期");
        }
        if (!JwtTokenProvider.TYPE_REFRESH.equals(parsed.type())) {
            throw new BizException(ErrorCode.UNAUTHORIZED, "token 类型错误");
        }
        User user = userRepository.findById(parsed.userId())
                .orElseThrow(() -> new BizException(ErrorCode.USER_NOT_FOUND));
        return issue(user, false);
    }

    private User register(LoginRequest request) {
        UserRole role = parseRole(request.getRole());
        User user = new User();
        user.setPhone(request.getPhone());
        user.setNickname("用户" + request.getPhone().substring(7));
        user.setRole(role);
        return userRepository.save(user);
        // TODO(2.1.2) 注册后引导完善资料：CUSTOMER → customer_profiles；ENGINEER → 引导提交资质认证
    }

    private UserRole parseRole(String role) {
        if (role == null || role.isBlank()) {
            return UserRole.CUSTOMER;
        }
        try {
            UserRole parsed = UserRole.valueOf(role.toUpperCase(Locale.ROOT));
            if (parsed == UserRole.ADMIN || parsed == UserRole.SYSTEM) {
                // 手机验证码登录不允许自助成为管理员
                return UserRole.CUSTOMER;
            }
            return parsed;
        } catch (IllegalArgumentException e) {
            return UserRole.CUSTOMER;
        }
    }

    private TokenResponse issue(User user, boolean isNew) {
        String access = tokenProvider.generateAccessToken(user.getId(), user.getPhone(), user.getRole());
        String refresh = tokenProvider.generateRefreshToken(user.getId(), user.getPhone(), user.getRole());
        return new TokenResponse(access, refresh, user.getId(), user.getRole().name(), isNew);
    }
}
