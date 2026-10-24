package com.repairhub.order.repository;

import com.repairhub.order.entity.OrderQuote;
import com.repairhub.order.enums.QuoteStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface OrderQuoteRepository extends JpaRepository<OrderQuote, Long> {

    List<OrderQuote> findByOrderIdOrderByCreatedAtDescIdDesc(Long orderId);

    Optional<OrderQuote> findFirstByOrderIdAndStatusOrderByIdDesc(Long orderId, QuoteStatus status);

    Optional<OrderQuote> findByIdAndOrderId(Long id, Long orderId);
}
