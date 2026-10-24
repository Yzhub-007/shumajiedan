package com.repairhub.thirdparty.map;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.concurrent.ThreadLocalRandom;

/**
 * 开发用 Mock 地理编码：返回随机坐标。真实地址请接入高德地理编码 API。
 */
@Component
@ConditionalOnProperty(name = "app.map.provider", havingValue = "mock", matchIfMissing = true)
public class MockMapService implements MapService {

    @Override
    public LngLat geocode(String address) {
        // 以上海为中心加随机偏移，仅供联调
        return new LngLat(121.4737 + ThreadLocalRandom.current().nextDouble(-0.05, 0.05),
                31.2304 + ThreadLocalRandom.current().nextDouble(-0.05, 0.05));
    }
}
