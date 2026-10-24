package com.repairhub.order.service;

import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.common.util.JsonUtils;
import com.repairhub.order.dto.QuoteRequest;
import com.repairhub.order.dto.QuoteResponse;
import com.repairhub.order.entity.Order;
import com.repairhub.order.entity.OrderQuote;
import com.repairhub.order.enums.QuoteStatus;
import com.repairhub.order.repository.OrderQuoteRepository;
import com.repairhub.order.repository.OrderRepository;
import com.repairhub.order.state.OrderAction;
import com.repairhub.user.entity.UserRole;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

/**
 * 报价：到达后提交 → 客户确认后进入维修中（计划书 3.1.6）。
 */
@Service
@RequiredArgsConstructor
public class QuoteService {

    private final OrderRepository orderRepository;
    private final OrderQuoteRepository quoteRepository;
    private final OrderActionService orderActionService;

    @Transactional
    public QuoteResponse submit(Long orderId, Long engineerId, QuoteRequest request) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BizException(ErrorCode.ORDER_NOT_FOUND));
        orderActionService.assertEngineerOwns(order, engineerId);
        if (order.getStatus() != com.repairhub.order.enums.OrderStatus.ARRIVED) {
            throw new BizException(ErrorCode.ORDER_STATE_ILLEGAL, "仅到达现场后可提交报价");
        }
        OrderQuote quote = new OrderQuote();
        quote.setOrderId(orderId);
        quote.setEngineerId(engineerId);
        quote.setLaborFee(request.getLaborFee());
        quote.setPartsFee(request.getPartsFee() == null ? BigDecimal.ZERO : request.getPartsFee());
        quote.setPartsDetail(JsonUtils.write(request.getPartsDetail()));
        quote.setTotal(quote.getLaborFee().add(quote.getPartsFee()));
        return QuoteResponse.from(quoteRepository.save(quote));
    }

    @Transactional
    public void accept(Long orderId, Long quoteId, Long customerId) {
        OrderQuote quote = quoteRepository.findByIdAndOrderId(quoteId, orderId)
                .orElseThrow(() -> new BizException(ErrorCode.QUOTE_NOT_FOUND));
        if (quote.getStatus() != QuoteStatus.PENDING) {
            throw new BizException(ErrorCode.CONFLICT, "该报价已处理");
        }
        orderActionService.apply(orderId, OrderAction.QUOTE_ACCEPT, customerId, UserRole.CUSTOMER, "客户确认报价");
        quote.setStatus(QuoteStatus.ACCEPTED);
        quoteRepository.save(quote);

        Order order = orderRepository.findById(orderId).orElseThrow();
        order.setQuoteAmount(quote.getTotal());
        orderRepository.save(order);
    }

    @Transactional
    public void reject(Long orderId, Long quoteId, Long customerId) {
        OrderQuote quote = quoteRepository.findByIdAndOrderId(quoteId, orderId)
                .orElseThrow(() -> new BizException(ErrorCode.QUOTE_NOT_FOUND));
        if (quote.getStatus() != QuoteStatus.PENDING) {
            throw new BizException(ErrorCode.CONFLICT, "该报价已处理");
        }
        quote.setStatus(QuoteStatus.REJECTED);
        quoteRepository.save(quote);
        // 拒绝后工程师可重新报价，工单保持 ARRIVED
    }
}
