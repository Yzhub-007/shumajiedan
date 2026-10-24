package com.repairhub.thirdparty.sms;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * 开发用 Mock 短信：只打日志。
 * 切换真实短信：app.sms.mock=false 并新增实现（如 AliyunSmsSender）。
 */
@Slf4j
@Component
@ConditionalOnProperty(name = "app.sms.mock", havingValue = "true", matchIfMissing = true)
public class MockSmsSender implements SmsSender {

    @Override
    public void send(String phone, String content) {
        log.info("[MOCK SMS] phone={} content={}", phone, content);
    }
}
