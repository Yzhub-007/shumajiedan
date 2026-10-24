package com.repairhub.auth.service;

import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.thirdparty.sms.SmsSender;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Duration;

/**
 * 短信验证码：Redis 存储与限流（计划书 2.1.1，防刷在发送侧做 60s 间隔）。
 */
@Service
@RequiredArgsConstructor
public class SmsCodeService {

    private static final String CODE_KEY = "sms:code:";
    private static final String LIMIT_KEY = "sms:limit:";
    private static final Duration CODE_TTL = Duration.ofMinutes(5);
    private static final Duration SEND_INTERVAL = Duration.ofSeconds(60);
    private static final SecureRandom RANDOM = new SecureRandom();

    private final StringRedisTemplate redis;
    private final SmsSender smsSender;

    /** 发送验证码，返回验证码明文（仅 mock 模式用于联调返回给前端） */
    public String sendCode(String phone) {
        Boolean first = redis.opsForValue().setIfAbsent(LIMIT_KEY + phone, "1", SEND_INTERVAL);
        if (!Boolean.TRUE.equals(first)) {
            throw new BizException(ErrorCode.SMS_SEND_TOO_FREQUENT);
        }
        String code = String.format("%06d", RANDOM.nextInt(1_000_000));
        redis.opsForValue().set(CODE_KEY + phone, code, CODE_TTL);
        smsSender.send(phone, "【机器报修】您的验证码是 " + code + "，5 分钟内有效，请勿泄露。");
        return code;
    }

    public void verify(String phone, String code) {
        String cached = redis.opsForValue().get(CODE_KEY + phone);
        if (cached == null || !cached.equals(code)) {
            throw new BizException(ErrorCode.SMS_CODE_INVALID);
        }
        redis.delete(CODE_KEY + phone);
    }
}
