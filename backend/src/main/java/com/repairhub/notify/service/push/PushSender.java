package com.repairhub.notify.service.push;

import java.util.Map;

/**
 * 系统推送适配器。生产接入极光推送 / 各厂商通道 + APNs（计划书 3.1.10、11 风险应对）。
 */
public interface PushSender {

    void push(Long userId, String title, String body, Map<String, Object> data);
}
