package com.repairhub.thirdparty.map;

/**
 * 地图服务适配器：地理编码、逆地理编码。生产接入高德开放平台（计划书 1.3.1）。
 */
public interface MapService {

    LngLat geocode(String address);

    record LngLat(double lng, double lat) {
    }
}
