package com.repairhub.user.repository;

import com.repairhub.user.entity.User;
import com.repairhub.user.entity.UserRole;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByPhone(String phone);

    boolean existsByPhone(String phone);

    Page<User> findByRole(UserRole role, Pageable pageable);
}
