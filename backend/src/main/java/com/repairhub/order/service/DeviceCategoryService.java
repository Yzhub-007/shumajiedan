package com.repairhub.order.service;

import com.repairhub.order.dto.CategoryResponse;
import com.repairhub.order.entity.DeviceCategory;
import com.repairhub.order.repository.DeviceCategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 设备类型字典（计划书 2.1.3）：客户端读启用项，后台 CRUD 见 admin 模块。
 */
@Service
@RequiredArgsConstructor
public class DeviceCategoryService {

    private final DeviceCategoryRepository deviceCategoryRepository;

    @Transactional(readOnly = true)
    public List<CategoryResponse> tree(boolean onlyEnabled) {
        List<DeviceCategory> all = onlyEnabled
                ? deviceCategoryRepository.findByEnabledTrueOrderBySortAscIdAsc()
                : deviceCategoryRepository.findAllByOrderBySortAscIdAsc();
        List<CategoryResponse> nodes = all.stream().map(CategoryResponse::from).toList();
        return nodes.stream()
                .filter(node -> node.getParentId() == null)
                .map(root -> attachChildren(root, nodes))
                .toList();
    }

    private CategoryResponse attachChildren(CategoryResponse parent, List<CategoryResponse> all) {
        parent.setChildren(all.stream()
                .filter(node -> parent.getId().equals(node.getParentId()))
                .map(child -> attachChildren(child, all))
                .toList());
        return parent;
    }
}
