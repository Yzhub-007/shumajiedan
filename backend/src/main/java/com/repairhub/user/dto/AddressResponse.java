package com.repairhub.user.dto;

import com.repairhub.user.entity.Address;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AddressResponse {

    private Long id;
    private String label;
    private String province;
    private String city;
    private String district;
    private String detail;
    private Double lng;
    private Double lat;
    private Boolean isDefault;

    public static AddressResponse from(Address address) {
        return AddressResponse.builder()
                .id(address.getId())
                .label(address.getLabel())
                .province(address.getProvince())
                .city(address.getCity())
                .district(address.getDistrict())
                .detail(address.getDetail())
                .lng(address.getLng())
                .lat(address.getLat())
                .isDefault(address.getIsDefault())
                .build();
    }
}
