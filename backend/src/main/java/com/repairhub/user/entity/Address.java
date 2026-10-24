package com.repairhub.user.entity;

import com.repairhub.common.domain.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "addresses")
@Getter
@Setter
public class Address extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(length = 50)
    private String label;

    @Column(length = 50)
    private String province;

    @Column(length = 50)
    private String city;

    @Column(length = 50)
    private String district;

    @Column(length = 200)
    private String detail;

    private Double lng;

    private Double lat;

    @Column(name = "is_default", nullable = false)
    private Boolean isDefault = false;
}
