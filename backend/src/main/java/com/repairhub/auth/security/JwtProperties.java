package com.repairhub.auth.security;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Data
@ConfigurationProperties(prefix = "app.jwt")
public class JwtProperties {

    private String secret;
    private int accessTokenTtlHours = 2;
    private int refreshTokenTtlDays = 30;
}
