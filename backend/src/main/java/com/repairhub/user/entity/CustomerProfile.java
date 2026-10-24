package com.repairhub.user.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

/**
 * 客户企业信息（主键 = user_id）。
 */
@Entity
@Table(name = "customer_profiles")
@Getter
@Setter
public class CustomerProfile {

    @Id
    private Long userId;

    @Column(name = "company_name", length = 100)
    private String companyName;

    @Column(name = "contact_name", length = 50)
    private String contactName;

    @Column(length = 50)
    private String industry;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
