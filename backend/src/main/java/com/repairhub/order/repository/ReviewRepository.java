package com.repairhub.order.repository;

import com.repairhub.order.entity.Review;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ReviewRepository extends JpaRepository<Review, Long> {

    List<Review> findByOrderId(Long orderId);

    boolean existsByOrderIdAndFromUserId(Long orderId, Long fromUserId);

    List<Review> findByToUserId(Long toUserId);

    /** 工程师评分聚合（计划书 3.1.9） */
    @Query("SELECT COALESCE(AVG(r.score), 5) FROM Review r WHERE r.toUserId = :userId")
    Double avgScoreByToUserId(@Param("userId") Long userId);
}
