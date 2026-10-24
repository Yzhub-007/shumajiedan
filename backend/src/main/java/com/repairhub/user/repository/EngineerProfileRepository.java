package com.repairhub.user.repository;

import com.repairhub.user.entity.EngineerProfile;
import com.repairhub.user.entity.VerifyStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface EngineerProfileRepository extends JpaRepository<EngineerProfile, Long> {

    Page<EngineerProfile> findByVerifyStatus(VerifyStatus verifyStatus, Pageable pageable);

    List<EngineerProfile> findByVerifyStatus(VerifyStatus verifyStatus);
}
