package com.repairhub.payment;

import org.springframework.stereotype.Service;

/**
 * 支付结算模块（V1.1 预留，计划书 3.2 / 11 支付合规）。
 *
 * 待实现内容：
 * - 微信支付 / 支付宝下单与回调（回调必须幂等，计划书 5.1.6）
 * - 平台抽佣与分账（优先使用微信分账/支付宝分账产品，规避二清风险）
 * - wallets / withdrawals 表的实体与服务（DDL 已就绪，见 V1__init.sql）
 * - 工程师提现与后台提现审核
 *
 * 当前 MVP：验收通过直接 COMPLETED（app.order.payment-enabled=false），线下结算。
 */
@Service
public class PaymentService {

    public void notImplemented() {
        throw new UnsupportedOperationException("支付功能计划于 V1.1 上线");
    }
}
