package com.repairhub.payment;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * 支付结算参数。
 */
@Data
@ConfigurationProperties(prefix = "app.payment")
public class PaymentProperties {

    /** 平台抽佣比例（0.10 = 10%），计划书 3.2 在线支付结算 */
    private double platformFeeRate = 0.10;

    /** 提现最低金额（元） */
    private double minWithdrawAmount = 10;
}
