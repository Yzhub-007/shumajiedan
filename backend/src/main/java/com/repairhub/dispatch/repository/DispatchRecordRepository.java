package com.repairhub.dispatch.repository;

import com.repairhub.dispatch.entity.DispatchRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DispatchRecordRepository extends JpaRepository<DispatchRecord, Long> {

    List<DispatchRecord> findByOrderId(Long orderId);
}
