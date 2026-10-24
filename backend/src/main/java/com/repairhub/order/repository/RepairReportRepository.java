package com.repairhub.order.repository;

import com.repairhub.order.entity.RepairReport;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface RepairReportRepository extends JpaRepository<RepairReport, Long> {

    Optional<RepairReport> findFirstByOrderIdOrderByCreatedAtDescIdDesc(Long orderId);
}
