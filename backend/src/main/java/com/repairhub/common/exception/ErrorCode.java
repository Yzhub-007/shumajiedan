package com.repairhub.common.exception;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 业务错误码。分段：40xxx 通用 / 20xxx 用户认证 / 30xxx 工单 / 50xxx 系统。
 */
@Getter
@AllArgsConstructor
public enum ErrorCode {

    PARAM_ERROR(40000, "参数错误"),
    UNAUTHORIZED(40100, "未登录或登录已过期"),
    FORBIDDEN(40300, "无权限操作"),
    NOT_FOUND(40400, "资源不存在"),
    CONFLICT(40900, "资源状态冲突"),

    SMS_SEND_TOO_FREQUENT(20001, "验证码发送过于频繁，请稍后再试"),
    SMS_CODE_INVALID(20002, "验证码错误或已过期"),
    USER_NOT_FOUND(20003, "用户不存在"),
    USER_DISABLED(20004, "账号已被禁用"),
    ENGINEER_NOT_APPROVED(20005, "工程师资质未通过审核，无法接单"),

    ORDER_NOT_FOUND(30001, "工单不存在"),
    ORDER_STATE_ILLEGAL(30002, "工单当前状态不允许该操作"),
    GRAB_CONFLICT(30003, "手慢了，该工单已被其他工程师接单"),
    QUOTE_NOT_FOUND(30004, "报价不存在"),
    ARRIVE_TOO_FAR(30005, "尚未到达服务地址附近，无法签到"),
    NO_NEARBY_ENGINEER(30006, "附近暂无可用工程师，已通知运营介入"),

    SYSTEM_ERROR(50000, "系统繁忙，请稍后再试");

    private final int code;
    private final String message;
}
