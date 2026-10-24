package com.repairhub.order.enums;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 报价状态。
 */
@Getter
@AllArgsConstructor
public enum QuoteStatus {

    PENDING("待确认"),
    ACCEPTED("已确认"),
    REJECTED("已拒绝");

    private final String label;
}
