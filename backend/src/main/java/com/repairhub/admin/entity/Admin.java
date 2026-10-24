package com.repairhub.admin.entity;

import com.repairhub.common.domain.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

/**
 * 后台管理员（用户名 + 密码登录，与 App 端手机号体系分离）。
 */
@Entity
@Table(name = "admins")
@Getter
@Setter
public class Admin extends BaseEntity {

    @Column(nullable = false, unique = true, length = 50)
    private String username;

    @Column(name = "password_hash", nullable = false, length = 100)
    private String passwordHash;

    /** SUPER_ADMIN / OPERATOR（RBAC 细化见 TODO(2.1.8)） */
    @Column(nullable = false, length = 20)
    private String role = "SUPER_ADMIN";

    @Column(nullable = false, length = 20)
    private String status = "ACTIVE";
}
