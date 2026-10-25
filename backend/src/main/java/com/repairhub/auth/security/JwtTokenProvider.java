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
import java.util.Map;

/**
 * JWT 签发与解析（jjwt 0.12，HS256）。
 * claims：sub=用户ID, phone, role, typ=access|refresh, adminRole(可选)
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
        return generateAccessToken(userId, phone, role, Map.of());
    }

    public String generateAccessToken(Long userId, String phone, UserRole role, Map<String, Object> extraClaims) {
        return build(userId, phone, role, TYPE_ACCESS,
                Duration.ofHours(props.getAccessTokenTtlHours()), extraClaims);
    }

    public String generateRefreshToken(Long userId, String phone, UserRole role) {
        return build(userId, phone, role, TYPE_REFRESH,
                Duration.ofDays(props.getRefreshTokenTtlDays()), Map.of());
    }

    /** 解析失败抛 io.jsonwebtoken.JwtException；过期抛 ExpiredJwtException。 */
    public ParsedToken parse(String token) {
        Claims claims = Jwts.parser().verifyWith(key).build()
                .parseSignedClaims(token).getPayload();
        return new ParsedToken(
                Long.valueOf(claims.getSubject()),
                claims.get("phone", String.class),
                claims.get("role", String.class),
                claims.get("typ", String.class),
                claims.get("adminRole", String.class));
    }

    private String build(Long userId, String phone, UserRole role, String type,
                         Duration ttl, Map<String, Object> extraClaims) {
        Instant now = Instant.now();
        var builder = Jwts.builder()
                .subject(String.valueOf(userId))
                .claim("phone", phone)
                .claim("role", role.name())
                .claim("typ", type)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plus(ttl)));
        extraClaims.forEach(builder::claim);
        return builder.signWith(key).compact();
    }

    public record ParsedToken(Long userId, String phone, String role, String type, String adminRole) {
    }
}
