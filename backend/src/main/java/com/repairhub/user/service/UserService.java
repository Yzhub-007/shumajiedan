package com.repairhub.user.service;

import com.repairhub.user.dto.CustomerProfileResponse;
import com.repairhub.user.dto.UpdateCustomerProfileRequest;
import com.repairhub.user.entity.CustomerProfile;
import com.repairhub.user.entity.User;
import com.repairhub.user.repository.CustomerProfileRepository;
import com.repairhub.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 客户资料（计划书 2.1.2）。
 */
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final CustomerProfileRepository customerProfileRepository;

    @Transactional(readOnly = true)
    public CustomerProfileResponse getProfile(Long userId) {
        User user = userRepository.findById(userId).orElseThrow();
        CustomerProfile profile = customerProfileRepository.findById(userId).orElse(null);
        return CustomerProfileResponse.from(user, profile);
    }

    @Transactional
    public CustomerProfileResponse updateProfile(Long userId, UpdateCustomerProfileRequest request) {
        User user = userRepository.findById(userId).orElseThrow();
        if (request.getNickname() != null && !request.getNickname().isBlank()) {
            user.setNickname(request.getNickname());
            userRepository.save(user);
        }
        CustomerProfile profile = customerProfileRepository.findById(userId)
                .orElseGet(() -> {
                    CustomerProfile created = new CustomerProfile();
                    created.setUserId(userId);
                    return created;
                });
        if (request.getCompanyName() != null) {
            profile.setCompanyName(request.getCompanyName());
        }
        if (request.getContactName() != null) {
            profile.setContactName(request.getContactName());
        }
        if (request.getIndustry() != null) {
            profile.setIndustry(request.getIndustry());
        }
        customerProfileRepository.save(profile);
        return CustomerProfileResponse.from(user, profile);
    }
}
