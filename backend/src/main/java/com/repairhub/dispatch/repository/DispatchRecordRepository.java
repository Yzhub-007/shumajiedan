package com.repairhub.dispatch.repository;

import com.repairhub.dispatch.entity.DispatchRecord;
import com.repairhub.dispatch.entity.DispatchType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DispatchRecordRepository extends JpaRepository<DispatchRecord, Long> {

    List<DispatchRecord> findByOrderId(Long orderId);

    List<DispatchRecord> findByOrderIdAndType(Long orderId, DispatchType type);
}
