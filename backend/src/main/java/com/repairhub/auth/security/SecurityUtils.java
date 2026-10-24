package com.repairhub.auth.security;

import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

/**
 * 取当前登录用户的静态工具。
 */
public final class SecurityUtils {

    private SecurityUtils() {
    }

    public static UserPrincipal current() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof UserPrincipal principal) {
            return principal;
        }
        throw new BizException(ErrorCode.UNAUTHORIZED);
    }

    public static Long currentUserId() {
        return current().userId();
    }

    public static String currentRole() {
        return current().role();
    }
}
