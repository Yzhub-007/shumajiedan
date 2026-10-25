package com.repairhub.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class TokenResponse {

    private String accessToken;
    private String refreshToken;
    private Long userId;
    private String role;
    private boolean newUser;

    /** 仅管理员登录时有值：SUPER_ADMIN / OPERATOR（RBAC，计划书 2.1.8） */
    private String adminRole;

    public TokenResponse(String accessToken, String refreshToken, Long userId, String role, boolean newUser) {
        this(accessToken, refreshToken, userId, role, newUser, null);
    }
}
