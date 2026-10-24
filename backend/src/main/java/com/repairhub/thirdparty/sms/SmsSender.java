package com.repairhub.thirdparty.sms;

/**
 * 短信发送适配器。生产替换为阿里云/腾讯云短信实现（计划书 1.3.1 需提前申请签名与模板）。
 */
public interface SmsSender {

    void send(String phone, String content);
}
