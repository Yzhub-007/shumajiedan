package com.repairhub.thirdparty.sms;

/**
 * 短信发送适配器（模板模式：内容由厂商侧审核过的签名/模板渲染，后端只传验证码，见 AliyunSmsSender）。
 */
public interface SmsSender {

    void sendVerifyCode(String phone, String code);
}
