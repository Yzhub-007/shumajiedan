package com.repairhub.order.repository;

import com.repairhub.order.entity.DeviceCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface DeviceCategoryRepository extends JpaRepository<DeviceCategory, Long> {

    List<DeviceCategory> findByEnabledTrueOrderBySortAscIdAsc();

    List<DeviceCategory> findAllByOrderBySortAscIdAsc();

    /** 工单设备类型改为可空后，多处按 id 联查需容忍 null（findById(null) 会抛 JPA 异常） */
    default DeviceCategory findByIdOrNull(Long id) {
        return id == null ? null : findById(id).orElse(null);
    }

    /** 手动输入的设备类型文本与字典名一致时回填关联，保留计价与技能匹配 */
    @Query("""
            SELECT c FROM DeviceCategory c
             WHERE lower(c.name) = lower(:name) AND c.enabled = true
             ORDER BY c.sort ASC, c.id ASC
            """)
    List<DeviceCategory> matchEnabledByName(@Param("name") String name);

    default Optional<DeviceCategory> findFirstByNameIgnoreCaseAndEnabledTrue(String name) {
        List<DeviceCategory> matches = matchEnabledByName(name);
        return matches.isEmpty() ? Optional.empty() : Optional.of(matches.get(0));
    }
}
