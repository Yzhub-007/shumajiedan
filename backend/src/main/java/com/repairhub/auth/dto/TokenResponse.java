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
}
