package com.repairhub.admin.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.repairhub.admin.entity.AdminOpLog;
import com.repairhub.admin.repository.AdminOpLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Map;

/**
 * 后台操作留痕。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AdminOpLogService {

    private final AdminOpLogRepository adminOpLogRepository;
    private final ObjectMapper objectMapper;

    public void record(Long adminId, String action, String target, Map<String, Object> detail) {
        try {
            AdminOpLog opLog = new AdminOpLog();
            opLog.setAdminId(adminId);
            opLog.setAction(action);
            opLog.setTarget(target);
            opLog.setDetail(objectMapper.writeValueAsString(detail == null ? Map.of() : detail));
            adminOpLogRepository.save(opLog);
        } catch (Exception e) {
            log.warn("操作日志写入失败 adminId={} action={}", adminId, action, e);
        }
    }
}
