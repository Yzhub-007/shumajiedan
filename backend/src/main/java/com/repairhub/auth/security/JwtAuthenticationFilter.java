package com.repairhub.auth.security;

import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

/**
 * Bearer token 解析 → SecurityContext。无效 token 直接置空，由授权规则决定放行或 401。
 */
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider tokenProvider;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            try {
                JwtTokenProvider.ParsedToken parsed = tokenProvider.parse(header.substring(7));
                if (JwtTokenProvider.TYPE_ACCESS.equals(parsed.type())) {
                    UserPrincipal principal = new UserPrincipal(parsed.userId(), parsed.phone(), parsed.role());
                    // ROLE_<角色> + 管理员细分角色（SUPER_ADMIN/OPERATOR，供 @PreAuthorize 使用）
                    java.util.List<SimpleGrantedAuthority> authorities = new java.util.ArrayList<>();
                    authorities.add(new SimpleGrantedAuthority("ROLE_" + parsed.role()));
                    if (parsed.adminRole() != null && !parsed.adminRole().isBlank()) {
                        authorities.add(new SimpleGrantedAuthority("ROLE_" + parsed.adminRole()));
                    }
                    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                            principal, null, authorities);
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            } catch (JwtException | IllegalArgumentException e) {
                SecurityContextHolder.clearContext();
            }
        }
        filterChain.doFilter(request, response);
    }
}
