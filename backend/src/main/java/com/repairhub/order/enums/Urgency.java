package com.repairhub.order.enums;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 紧急程度：影响派单半径与预估加价。
 */
@Getter
@AllArgsConstructor
public enum Urgency {

    NORMAL("普通", 1.0),
    URGENT("紧急", 1.5),
    CRITICAL("特急", 2.0);

    private final String label;
    private final double surchargeMultiplier;
}
