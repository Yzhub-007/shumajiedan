package com.repairhub.admin.repository;

import com.repairhub.admin.entity.AdminOpLog;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AdminOpLogRepository extends JpaRepository<AdminOpLog, Long> {
}
