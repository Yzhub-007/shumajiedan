package com.repairhub.payment.repository;

import com.repairhub.payment.entity.Withdrawal;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface WithdrawalRepository extends JpaRepository<Withdrawal, Long> {

    List<Withdrawal> findByUserIdOrderByCreatedAtDesc(Long userId);

    Page<Withdrawal> findByStatus(String status, Pageable pageable);
}
