package com.repairhub.user.repository;

import com.repairhub.user.entity.Address;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AddressRepository extends JpaRepository<Address, Long> {

    List<Address> findByUserIdOrderByIsDefaultDescUpdatedAtDesc(Long userId);

    List<Address> findByUserId(Long userId);
}
