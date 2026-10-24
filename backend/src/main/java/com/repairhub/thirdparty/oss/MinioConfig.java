package com.repairhub.thirdparty.oss;

import io.minio.MinioClient;
import okhttp3.HttpUrl;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * MinIO 客户端（app.oss.provider=minio 时生效）。
 */
@Configuration
@ConditionalOnProperty(name = "app.oss.provider", havingValue = "minio")
public class MinioConfig {

    @Bean
    public MinioClient minioClient(@Value("${app.oss.minio.endpoint}") String endpoint,
                                   @Value("${app.oss.minio.access-key}") String accessKey,
                                   @Value("${app.oss.minio.secret-key}") String secretKey) {
        return MinioClient.builder()
                .endpoint(HttpUrl.parse(endpoint))
                .credentials(accessKey, secretKey)
                .build();
    }
}
