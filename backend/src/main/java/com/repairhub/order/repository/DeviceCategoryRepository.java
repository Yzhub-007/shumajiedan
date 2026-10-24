package com.repairhub.order.repository;

import com.repairhub.order.entity.DeviceCategory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DeviceCategoryRepository extends JpaRepository<DeviceCategory, Long> {

    List<DeviceCategory> findByEnabledTrueOrderBySortAscIdAsc();

    List<DeviceCategory> findAllByOrderBySortAscIdAsc();
}
