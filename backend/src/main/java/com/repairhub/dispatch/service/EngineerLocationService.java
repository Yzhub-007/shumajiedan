package com.repairhub.dispatch.service;

import lombok.RequiredArgsConstructor;
import org.springframework.data.geo.Circle;
import org.springframework.data.geo.Distance;
import org.springframework.data.geo.GeoResult;
import org.springframework.data.geo.GeoResults;
import org.springframework.data.geo.Metrics;
import org.springframework.data.geo.Point;
import org.springframework.data.redis.connection.RedisGeoCommands;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 工程师实时位置（Redis GEO，计划书 5.1.1）。
 * 上线后每 10~15s 上报 → GEOADD engineers:online；发单时 GEOSEARCH 半径内在线工程师。
 */
@Service
@RequiredArgsConstructor
public class EngineerLocationService {

    public static final String ONLINE_KEY = "engineers:online";

    private final StringRedisTemplate redis;

    public void online(Long engineerId, double lng, double lat) {
        redis.opsForGeo().add(ONLINE_KEY, new Point(lng, lat), String.valueOf(engineerId));
    }

    public void offline(Long engineerId) {
        redis.opsForGeo().remove(ONLINE_KEY, String.valueOf(engineerId));
    }

    /** 半径内在线工程师，按距离升序 */
    public List<NearbyEngineer> searchNearby(double lng, double lat, double radiusKm) {
        GeoResults<org.springframework.data.redis.connection.RedisGeoCommands.GeoLocation<String>> results =
                redis.opsForGeo()
                        .radius(ONLINE_KEY,
                                new Circle(new Point(lng, lat), new Distance(radiusKm, Metrics.KILOMETERS)),
                                RedisGeoCommands.GeoRadiusCommandArgs.newGeoRadiusArgs()
                                        .includeDistance()
                                        .sortAscending());
        if (results == null) {
            return List.of();
        }
        return results.getContent().stream()
                .map(this::toNearby)
                .toList();
    }

    public long countNearby(double lng, double lat, double radiusKm) {
        return searchNearby(lng, lat, radiusKm).size();
    }

    private NearbyEngineer toNearby(
            GeoResult<org.springframework.data.redis.connection.RedisGeoCommands.GeoLocation<String>> result) {
        long engineerId = Long.parseLong(result.getContent().getName());
        // 距离单位与查询一致（KILOMETERS）
        int distanceM = result.getDistance() == null ? 0
                : (int) Math.round(result.getDistance().getValue() * 1000);
        return new NearbyEngineer(engineerId, distanceM);
    }

    public record NearbyEngineer(Long engineerId, int distanceM) {
    }
}
