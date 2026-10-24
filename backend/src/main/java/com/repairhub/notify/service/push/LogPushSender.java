package com.repairhub.notify.service.push;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * 开发用 Mock 推送：打日志。
 * TODO(3.1.10) 接入极光推送：新增 JiguangPushSender 并按配置切换。
 */
@Slf4j
@Component
public class LogPushSender implements PushSender {

    @Override
    public void push(Long userId, String title, String body, Map<String, Object> data) {
        log.info("[MOCK PUSH] userId={} title={} body={} data={}", userId, title, body, data);
    }
}
