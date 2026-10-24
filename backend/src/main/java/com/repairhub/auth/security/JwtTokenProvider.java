package com.repairhub.auth.security;

import com.repairhub.user.entity.UserRole;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;

/**
 * JWT 签发与解析（jjwt 0.12，HS256）。
 * claims：sub=用户ID, phone, role, typ=access|refresh
 */
@Component
public class JwtTokenProvider {

    public static final String TYPE_ACCESS = "access";
    public static final String TYPE_REFRESH = "refresh";

    private final SecretKey key;
    private final JwtProperties props;

    public JwtTokenProvider(JwtProperties props) {
        this.props = props;
        this.key = Keys.hmacShaKeyFor(props.getSecret().getBytes(StandardCharsets.UTF_8));
    }

    public String generateAccessToken(Long userId, String phone, UserRole role) {
        return build(userId, phone, role, TYPE_ACCESS, Duration.ofHours(props.getAccessTokenTtlHours()));
    }

    public String generateRefreshToken(Long userId, String phone, UserRole role) {
        return build(userId, phone, role, TYPE_REFRESH, Duration.ofDays(props.getRefreshTokenTtlDays()));
    }

    /** 解析失败抛 io.jsonwebtoken.JwtException；过期抛 ExpiredJwtException。 */
    public ParsedToken parse(String token) {
        Claims claims = Jwts.parser().verifyWith(key).build()
                .parseSignedClaims(token).getPayload();
        return new ParsedToken(
                Long.valueOf(claims.getSubject()),
                claims.get("phone", String.class),
                claims.get("role", String.class),
                claims.get("typ", String.class));
    }

    private String build(Long userId, String phone, UserRole role, String type, Duration ttl) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .claim("phone", phone)
                .claim("role", role.name())
                .claim("typ", type)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plus(ttl)))
                .signWith(key)
                .compact();
    }

    public record ParsedToken(Long userId, String phone, String role, String type) {
    }
}
