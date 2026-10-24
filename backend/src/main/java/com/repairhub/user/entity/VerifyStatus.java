package com.repairhub.user.entity;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 工程师资质审核状态。
 */
@Getter
@AllArgsConstructor
public enum VerifyStatus {

    PENDING("待审核"),
    APPROVED("已通过"),
    REJECTED("已拒绝");

    private final String label;
}
