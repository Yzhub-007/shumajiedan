package com.repairhub.common.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * 工单相关业务参数（order 与 dispatch 模块共用）。
 */
@Data
@ConfigurationProperties(prefix = "app.order")
public class OrderProperties {

    /** MVP 不接支付：验收通过直接 COMPLETED */
    private boolean paymentEnabled = false;

    /** 到达签到 GPS 校验半径（米），计划书 3.1.5 */
    private int arriveCheckRadiusM = 500;

    /** 派单半径（公里），计划书 5.1.1 */
    private int dispatchRadiusKm = 5;
}
