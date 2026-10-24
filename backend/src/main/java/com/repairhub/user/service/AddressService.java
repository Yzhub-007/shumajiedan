package com.repairhub.user.service;

import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.user.dto.AddressRequest;
import com.repairhub.user.dto.AddressResponse;
import com.repairhub.user.entity.Address;
import com.repairhub.user.repository.AddressRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 客户常用地址（计划书 2.1.2）。坐标由端侧地图选点写入；后端地理编码兜底 TODO 接高德。
 */
@Service
@RequiredArgsConstructor
public class AddressService {

    private final AddressRepository addressRepository;

    @Transactional(readOnly = true)
    public List<AddressResponse> list(Long userId) {
        return addressRepository.findByUserIdOrderByIsDefaultDescUpdatedAtDesc(userId).stream()
                .map(AddressResponse::from).toList();
    }

    @Transactional
    public AddressResponse create(Long userId, AddressRequest request) {
        Address address = new Address();
        apply(address, userId, request);
        List<Address> existing = addressRepository.findByUserId(userId);
        boolean first = existing.isEmpty();
        if (first || Boolean.TRUE.equals(request.getIsDefault())) {
            clearDefault(userId);
            address.setIsDefault(true);
        }
        return AddressResponse.from(addressRepository.save(address));
    }

    @Transactional
    public AddressResponse update(Long userId, Long id, AddressRequest request) {
        Address address = requireOwn(userId, id);
        apply(address, userId, request);
        if (Boolean.TRUE.equals(request.getIsDefault())) {
            clearDefault(userId);
            address.setIsDefault(true);
        }
        return AddressResponse.from(addressRepository.save(address));
    }

    @Transactional
    public void delete(Long userId, Long id) {
        addressRepository.delete(requireOwn(userId, id));
    }

    private void apply(Address address, Long userId, AddressRequest request) {
        address.setUserId(userId);
        address.setLabel(request.getLabel());
        address.setProvince(request.getProvince());
        address.setCity(request.getCity());
        address.setDistrict(request.getDistrict());
        address.setDetail(request.getDetail());
        address.setLng(request.getLng());
        address.setLat(request.getLat());
    }

    private void clearDefault(Long userId) {
        addressRepository.findByUserId(userId).stream()
                .filter(a -> Boolean.TRUE.equals(a.getIsDefault()))
                .forEach(a -> {
                    a.setIsDefault(false);
                    addressRepository.save(a);
                });
    }

    private Address requireOwn(Long userId, Long id) {
        Address address = addressRepository.findById(id)
                .orElseThrow(() -> new BizException(ErrorCode.NOT_FOUND, "地址不存在"));
        if (!address.getUserId().equals(userId)) {
            throw new BizException(ErrorCode.FORBIDDEN);
        }
        return address;
    }
}
