package com.repairhub.common.exception;

import lombok.Getter;

/**
 * 业务异常：携带错误码，由 GlobalExceptionHandler 统一转成 JSON 响应。
 */
@Getter
public class BizException extends RuntimeException {

    private final ErrorCode errorCode;

    public BizException(ErrorCode errorCode) {
        super(errorCode.getMessage());
        this.errorCode = errorCode;
    }

    public BizException(ErrorCode errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
    }
}
