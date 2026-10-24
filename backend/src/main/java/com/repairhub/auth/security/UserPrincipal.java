package com.repairhub.auth.security;

/**
 * 当前登录用户上下文对象（存入 SecurityContext）。
 */
public record UserPrincipal(Long userId, String phone, String role) {
}
