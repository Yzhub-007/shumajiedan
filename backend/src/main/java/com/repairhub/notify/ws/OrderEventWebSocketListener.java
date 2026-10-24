package com.repairhub.notify.ws;

import com.repairhub.order.event.OrderStatusChangedEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * 工单事件 → WebSocket 广播（计划书 5.1.5）。
 * 客户端订阅 /topic/order/{orderId}，接收状态变更与工程师位置推送。
 */
@Component
@RequiredArgsConstructor
public class OrderEventWebSocketListener {

    private final SimpMessagingTemplate messagingTemplate;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void onOrderStatusChanged(OrderStatusChangedEvent event) {
        messagingTemplate.convertAndSend("/topic/order/" + event.orderId(), Map.of(
                "type", "ORDER_STATUS_CHANGED",
                "orderId", event.orderId(),
                "from", event.from() == null ? "" : event.from().name(),
                "to", event.to().name(),
                "action", event.action().name(),
                "at", LocalDateTime.now().toString()));
    }
}
