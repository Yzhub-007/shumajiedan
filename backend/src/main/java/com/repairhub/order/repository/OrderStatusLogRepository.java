package com.repairhub.order.repository;

import com.repairhub.order.entity.OrderStatusLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface OrderStatusLogRepository extends JpaRepository<OrderStatusLog, Long> {

    List<OrderStatusLog> findByOrderIdOrderByCreatedAtAscIdAsc(Long orderId);
}
