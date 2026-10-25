package com.repairhub.order.repository;

import com.repairhub.order.entity.Order;
import com.repairhub.order.enums.OrderStatus;
import jakarta.persistence.LockModeType;
import jakarta.persistence.QueryHint;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.QueryHints;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface OrderRepository extends JpaRepository<Order, Long> {

    /** 历史记忆推荐的聚合投影（native SQL 列别名映射） */
    interface DeviceHistoryProjection {
        String getDeviceType();
        String getDeviceBrand();
        String getDeviceModel();
        Long getUseCount();
        java.sql.Timestamp getLastUsedAt();
    }

    boolean existsByOrderNo(String orderNo);

    Page<Order> findByCustomerId(Long customerId, Pageable pageable);

    Page<Order> findByCustomerIdAndStatus(Long customerId, OrderStatus status, Pageable pageable);

    Page<Order> findByEngineerId(Long engineerId, Pageable pageable);

    Page<Order> findByEngineerIdAndStatus(Long engineerId, OrderStatus status, Pageable pageable);

    Page<Order> findByStatus(OrderStatus status, Pageable pageable);

    Page<Order> findByOrderNoContainingIgnoreCase(String orderNo, Pageable pageable);

    long countByCreatedAtAfter(LocalDateTime time);

    List<Order> findByStatusIn(List<OrderStatus> statuses);

    List<Order> findByCreatedAtAfter(LocalDateTime time);

    long countByStatus(OrderStatus status);

    long countByEngineerId(Long engineerId);

    long countByEngineerIdAndStatusIn(Long engineerId, List<OrderStatus> statuses);

    /** 抢单/指派用条件更新：仅当仍为 PENDING 时成功（乐观锁语义，计划书 5.1.2） */
    @Modifying
    @Query("""
            UPDATE Order o
               SET o.engineerId = :engineerId, o.status = :accepted, o.acceptedAt = :acceptedAt
             WHERE o.id = :orderId AND o.status = :pending
            """)
    int grab(@Param("orderId") Long orderId,
             @Param("engineerId") Long engineerId,
             @Param("accepted") OrderStatus accepted,
             @Param("pending") OrderStatus pending,
             @Param("acceptedAt") LocalDateTime acceptedAt);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @QueryHints(@QueryHint(name = "jakarta.persistence.lock.timeout", value = "3000"))
    @Query("SELECT o FROM Order o WHERE o.id = :id")
    Optional<Order> findByIdForUpdate(@Param("id") Long id);

    @Query("""
            SELECT COALESCE(SUM(o.finalAmount), 0)
              FROM Order o
             WHERE o.engineerId = :engineerId AND o.status IN :statuses
            """)
    BigDecimal sumIncome(@Param("engineerId") Long engineerId, @Param("statuses") List<OrderStatus> statuses);

    /** 历史记忆推荐：用户工单的设备组合（类型+品牌+型号）去重，按最近使用排序 */
    @Query(value = """
            SELECT COALESCE(o.device_category_input, c.name) AS deviceType,
                   o.device_brand AS deviceBrand,
                   o.device_model AS deviceModel,
                   COUNT(*) AS useCount,
                   MAX(o.created_at) AS lastUsedAt
              FROM orders o
              LEFT JOIN device_categories c ON c.id = o.device_category_id
             WHERE o.customer_id = :customerId
               AND COALESCE(o.device_category_input, c.name) IS NOT NULL
             GROUP BY COALESCE(o.device_category_input, c.name), o.device_brand, o.device_model
             ORDER BY MAX(o.created_at) DESC
             LIMIT :limit
            """, nativeQuery = true)
    List<DeviceHistoryProjection> findDeviceHistory(@Param("customerId") Long customerId,
                                                    @Param("limit") int limit);
}
