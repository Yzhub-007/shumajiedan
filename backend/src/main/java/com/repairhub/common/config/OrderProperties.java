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

    /** 技能匹配开关：开启后仅推送给 skill_tags 命中设备类型的工程师 */
    private boolean smartDispatchSkillMatch = true;

    /** PENDING 超过 N 分钟无人接单 → 扩大半径重派（计划书 2.2 超时规则） */
    private int pendingTimeoutMinutes = 15;

    /** ACCEPTED 超过 N 分钟未出发 → 提醒工程师 */
    private int departRemindMinutes = 30;

    /** ACCEPTED 超过 N 分钟未出发 → 自动释放回单池 */
    private int departReleaseMinutes = 60;

    /** PENDING_CONFIRM 超过 N 小时未验收 → 自动验收通过 */
    private int autoConfirmHours = 48;
}
