package com.repairhub.common.util;

/**
 * 地理计算工具（Haversine）。PostGIS/Redis GEO 之外的轻量距离校验用。
 */
public final class GeoUtils {

    private static final double EARTH_RADIUS_M = 6371000.0;

    private GeoUtils() {
    }

    /** 两点球面距离（米） */
    public static double distanceMeters(double lng1, double lat1, double lng2, double lat2) {
        double radLat1 = Math.toRadians(lat1);
        double radLat2 = Math.toRadians(lat2);
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(radLat1) * Math.cos(radLat2) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        return EARTH_RADIUS_M * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }
}
