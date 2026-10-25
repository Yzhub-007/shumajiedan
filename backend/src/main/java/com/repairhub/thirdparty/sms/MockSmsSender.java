package com.repairhub.thirdparty.sms;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * 开发用 Mock 短信：只打日志。
 * 切换真实短信：app.sms.mock=false，并配置 app.sms.aliyun.*（AK 走环境变量注入）。
 */
@Slf4j
@Component
@ConditionalOnProperty(name = "app.sms.mock", havingValue = "true", matchIfMissing = true)
public class MockSmsSender implements SmsSender {

    @Override
    public void sendVerifyCode(String phone, String code) {
        log.info("[MOCK SMS] phone={} code={}", phone, code);
    }
}
