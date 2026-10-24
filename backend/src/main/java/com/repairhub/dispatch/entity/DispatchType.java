package com.repairhub.dispatch.entity;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 派单记录类型：谁被推送了、谁抢了、谁指派了、谁拒了（计划书第 6 节）。
 */
@Getter
@AllArgsConstructor
public enum DispatchType {

    PUSH("系统推送"),
    GRAB("工程师抢单"),
    ASSIGN("后台指派"),
    REJECT("工程师拒绝");

    private final String label;
}
