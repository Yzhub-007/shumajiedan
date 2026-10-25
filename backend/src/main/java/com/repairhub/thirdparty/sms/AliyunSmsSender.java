package com.repairhub.thirdparty.sms;

import com.aliyun.dysmsapi20170525.Client;
import com.aliyun.dysmsapi20170525.models.SendSmsRequest;
import com.aliyun.dysmsapi20170525.models.SendSmsResponseBody;
import com.aliyun.dysmsapi20170525.models.SendSmsResponse;
import com.aliyun.tea.TeaException;
import com.aliyun.teaopenapi.models.Config;
import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * 阿里云短信实现。前置条件：控制台已完成资质/签名/模板审核，
 * sign-name 与 template-code 填审核通过的值（签名内容形如"机器报修"，模板含 ${code} 变量）。
 * AK 通过环境变量 ALIYUN_SMS_ACCESS_KEY_ID / ALIYUN_SMS_ACCESS_KEY_SECRET 注入，勿写死提交。
 */
@Slf4j
@Component
@ConditionalOnProperty(name = "app.sms.mock", havingValue = "false")
public class AliyunSmsSender implements SmsSender {

    private final Client client;
    private final String signName;
    private final String templateCode;

    public AliyunSmsSender(
            @Value("${app.sms.aliyun.access-key-id}") String accessKeyId,
            @Value("${app.sms.aliyun.access-key-secret}") String accessKeySecret,
            @Value("${app.sms.aliyun.sign-name}") String signName,
            @Value("${app.sms.aliyun.template-code}") String templateCode) throws Exception {
        this.client = new Client(new Config()
                .setAccessKeyId(accessKeyId)
                .setAccessKeySecret(accessKeySecret)
                .setEndpoint("dysmsapi.aliyuncs.com"));
        this.signName = signName;
        this.templateCode = templateCode;
    }

    @Override
    public void sendVerifyCode(String phone, String code) {
        SendSmsRequest request = new SendSmsRequest()
                .setPhoneNumbers(phone)
                .setSignName(signName)
                .setTemplateCode(templateCode)
                .setTemplateParam("{\"code\":\"" + code + "\"}");
        SendSmsResponse response;
        try {
            response = client.sendSms(request);
        } catch (TeaException e) {
            log.error("阿里云短信调用异常 phone={}", phone, e);
            throw new BizException(ErrorCode.SMS_SEND_FAIL);
        } catch (Exception e) {
            log.error("阿里云短信调用失败 phone={}", phone, e);
            throw new BizException(ErrorCode.SMS_SEND_FAIL);
        }
        SendSmsResponseBody body = response.getBody();
        // Code=OK 表示阿里云已受理；常见拒绝：isv.BUSINESS_LIMIT_CONTROL（频控）、isv.SIGN_* / isv.TEMPLATE_*
        if (body == null || !"OK".equals(body.getCode())) {
            log.error("阿里云短信发送被拒 phone={} code={} message={}",
                    phone, body == null ? "无响应体" : body.getCode(), body == null ? "-" : body.getMessage());
            throw new BizException(ErrorCode.SMS_SEND_FAIL);
        }
        log.info("阿里云短信已受理 phone={} requestId={} bizId={}", phone, body.getRequestId(), body.getBizId());
    }
}
