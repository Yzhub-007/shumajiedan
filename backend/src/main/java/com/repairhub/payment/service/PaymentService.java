package com.repairhub.payment.service;

import com.repairhub.common.config.OrderProperties;
import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.notify.service.NotificationService;
import com.repairhub.order.entity.Order;
import com.repairhub.order.enums.OrderStatus;
import com.repairhub.order.repository.OrderRepository;
import com.repairhub.order.service.OrderActionService;
import com.repairhub.order.state.OrderAction;
import com.repairhub.payment.entity.Payment;
import com.repairhub.payment.repository.PaymentRepository;
import com.repairhub.user.entity.UserRole;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

/**
 * 支付结算（计划书 3.2 / 11 支付合规）。
 *
 * 当前实现 MOCK 渠道：客户确认验收后（payment-enabled=true 进入 PENDING_PAYMENT），
 * 调用支付接口直接成功并完成订单 → 工程师钱包入账（扣除平台抽佣）。
 *
 * TODO(V1.1) 真实渠道：微信/支付宝统一下单 + 异步回调（回调必须幂等：
 *   先按 trade_no 查支付单状态，已 PAID 直接返回成功）；
 *   分账优先使用微信分账/支付宝分账产品，规避二清风险。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentService {

    private static final DateTimeFormatter TRADE_NO_FORMAT = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

    private final OrderRepository orderRepository;
    private final OrderActionService orderActionService;
    private final PaymentRepository paymentRepository;
    private final WalletService walletService;
    private final NotificationService notificationService;
    private final com.repairhub.payment.PaymentProperties paymentProperties;
    private final OrderProperties orderProperties;

    @Transactional
    public Map<String, Object> payOrder(Long orderId, Long customerId, String channel) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BizException(ErrorCode.ORDER_NOT_FOUND));
        if (!order.getCustomerId().equals(customerId)) {
            throw new BizException(ErrorCode.FORBIDDEN);
        }
        if (order.getStatus() != OrderStatus.PENDING_PAYMENT) {
            throw new BizException(ErrorCode.ORDER_STATE_ILLEGAL, "当前状态无需支付");
        }
        BigDecimal amount = order.getFinalAmount() != null
                ? order.getFinalAmount()
                : order.getQuoteAmount();
        if (amount == null || amount.signum() < 0) {
            throw new BizException(ErrorCode.CONFLICT, "订单无应付金额，请联系客服");
        }

        // MOCK 渠道：直接支付成功。真实渠道此处应创建预支付单并返回唤起参数。
        Payment payment = new Payment();
        payment.setOrderId(orderId);
        payment.setAmount(amount);
        payment.setChannel(channel == null || channel.isBlank() ? "MOCK" : channel);
        payment.setTradeNo("M" + LocalDateTime.now().format(TRADE_NO_FORMAT)
                + String.format("%04d", ThreadLocalRandom.current().nextInt(10000)));
        payment.setStatus("PAID");
        payment.setPaidAt(LocalDateTime.now());
        paymentRepository.save(payment);

        // 幂等由状态机保证：PAY 仅允许 PENDING_PAYMENT → COMPLETED，重复支付会被拒绝
        orderActionService.apply(orderId, OrderAction.PAY, customerId, UserRole.CUSTOMER,
                "支付完成（" + payment.getChannel() + "）");

        // 平台抽佣 + 工程师入账
        if (order.getEngineerId() != null && amount.signum() > 0) {
            BigDecimal fee = amount.multiply(BigDecimal.valueOf(paymentProperties.getPlatformFeeRate()))
                    .setScale(2, RoundingMode.HALF_UP);
            order.setPlatformFee(fee);
            orderRepository.save(order);
            walletService.credit(order.getEngineerId(), amount.subtract(fee));
            notificationService.send(order.getEngineerId(), "INCOME", "订单收入已入账",
                    "订单 " + order.getOrderNo() + " 已支付，入账 " + amount.subtract(fee)
                            + " 元（平台服务费 " + fee + " 元）",
                    Map.of("orderId", orderId));
        }
        log.info("订单 {} 支付完成 amount={} channel={}", orderId, amount, payment.getChannel());
        return Map.of("paid", true, "tradeNo", payment.getTradeNo(), "amount", amount);
    }

    /** 是否启用支付（决定验收后是否进入待支付） */
    public boolean paymentEnabled() {
        return orderProperties.isPaymentEnabled();
    }
}
