package com.repairhub.user.entity;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 用户角色。客户端与工程师端为同一 App 的两种身份（计划书 2.1）。
 */
@Getter
@AllArgsConstructor
public enum UserRole {

    CUSTOMER("客户"),
    ENGINEER("工程师"),
    ADMIN("管理员"),
    SYSTEM("系统");

    private final String label;
}
