package com.repairhub.user.entity;

import com.repairhub.common.domain.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "users", indexes = @Index(name = "idx_users_role", columnList = "role"))
@Getter
@Setter
public class User extends BaseEntity {

    @Column(nullable = false, unique = true, length = 20)
    private String phone;

    private String passwordHash;

    @Column(length = 50)
    private String nickname;

    @Column(name = "avatar_url", length = 500)
    private String avatarUrl;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private UserRole role;

    /** ACTIVE / DISABLED */
    @Column(nullable = false, length = 20)
    private String status = "ACTIVE";
}
