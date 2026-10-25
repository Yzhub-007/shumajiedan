package com.repairhub.payment.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.notify.service.NotificationService;
import com.repairhub.payment.PaymentProperties;
import com.repairhub.payment.entity.Wallet;
import com.repairhub.payment.entity.Withdrawal;
import com.repairhub.payment.repository.WalletRepository;
import com.repairhub.payment.repository.WithdrawalRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * 钱包与提现（计划书 3.2）：支付完成后工程师入账；提现申请冻结余额，后台审核后打款。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class WalletService {

    private final WalletRepository walletRepository;
    private final WithdrawalRepository withdrawalRepository;
    private final NotificationService notificationService;
    private final PaymentProperties paymentProperties;
    private final ObjectMapper objectMapper;

    @Transactional
    public Wallet getOrCreate(Long userId) {
        return walletRepository.findById(userId).orElseGet(() -> {
            Wallet wallet = new Wallet();
            wallet.setUserId(userId);
            return walletRepository.save(wallet);
        });
    }

    /** 工程师收入入账（订单支付完成后调用） */
    @Transactional
    public void credit(Long userId, BigDecimal amount) {
        if (amount == null || amount.signum() <= 0) {
            return;
        }
        Wallet wallet = getOrCreate(userId);
        wallet.setBalance(wallet.getBalance().add(amount));
        wallet.setTotalIncome(wallet.getTotalIncome().add(amount));
        walletRepository.save(wallet);
    }

    @Transactional
    public Withdrawal applyWithdrawal(Long userId, BigDecimal amount, Map<String, Object> accountInfo) {
        if (amount == null || amount.signum() <= 0) {
            throw new BizException(ErrorCode.PARAM_ERROR, "提现金额不合法");
        }
        BigDecimal min = BigDecimal.valueOf(paymentProperties.getMinWithdrawAmount());
        if (amount.compareTo(min) < 0) {
            throw new BizException(ErrorCode.PARAM_ERROR, "最低提现金额 " + min.stripTrailingZeros().toPlainString() + " 元");
        }
        Wallet wallet = getOrCreate(userId);
        if (wallet.getBalance().compareTo(amount) < 0) {
            throw new BizException(ErrorCode.CONFLICT, "余额不足");
        }
        wallet.setBalance(wallet.getBalance().subtract(amount));
        wallet.setFrozen(wallet.getFrozen().add(amount));
        walletRepository.save(wallet);

        Withdrawal withdrawal = new Withdrawal();
        withdrawal.setUserId(userId);
        withdrawal.setAmount(amount);
        withdrawal.setAccountInfo(toJson(accountInfo));
        withdrawal = withdrawalRepository.save(withdrawal);
        log.info("工程师 {} 申请提现 {}", userId, amount);
        return withdrawal;
    }

    @Transactional(readOnly = true)
    public Page<Withdrawal> page(String status, int page, int size) {
        Pageable pageable = PageRequest.of(Math.max(page - 1, 0), Math.min(size, 100),
                Sort.by(Sort.Direction.DESC, "createdAt"));
        return (status == null || status.isBlank())
                ? withdrawalRepository.findAll(pageable)
                : withdrawalRepository.findByStatus(status, pageable);
    }

    @Transactional(readOnly = true)
    public List<Withdrawal> myWithdrawals(Long userId) {
        return withdrawalRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    /** 后台审核：通过则冻结扣减（打款渠道接入见 TODO(V1.1)），拒绝则退回余额 */
    @Transactional
    public void review(Long withdrawalId, boolean approve, Long adminId, String reason) {
        Withdrawal withdrawal = withdrawalRepository.findById(withdrawalId)
                .orElseThrow(() -> new BizException(ErrorCode.NOT_FOUND, "提现申请不存在"));
        if (!"PENDING".equals(withdrawal.getStatus())) {
            throw new BizException(ErrorCode.CONFLICT, "该申请已处理");
        }
        Wallet wallet = getOrCreate(withdrawal.getUserId());
        wallet.setFrozen(wallet.getFrozen().subtract(withdrawal.getAmount()));
        if (approve) {
            withdrawal.setStatus("APPROVED");
            // TODO(V1.1) 对接微信商家转账/支付宝转账打款，打款失败时人工处理
        } else {
            withdrawal.setStatus("REJECTED");
            withdrawal.setRejectReason(reason);
            wallet.setBalance(wallet.getBalance().add(withdrawal.getAmount()));
        }
        withdrawal.setReviewedBy(adminId);
        withdrawalRepository.save(withdrawal);
        walletRepository.save(wallet);

        notificationService.send(withdrawal.getUserId(), "WITHDRAWAL_REVIEW",
                approve ? "提现已通过" : "提现被拒绝",
                approve ? "提现 " + withdrawal.getAmount() + " 元已通过审核，打款处理中"
                        : "提现 " + withdrawal.getAmount() + " 元被拒绝：" + reason + "，金额已退回余额",
                Map.of("withdrawalId", withdrawalId));
    }

    private String toJson(Map<String, Object> data) {
        try {
            return objectMapper.writeValueAsString(data == null ? Map.of() : data);
        } catch (Exception e) {
            return "{}";
        }
    }
}
