package com.repairhub.thirdparty.oss;

import io.minio.GetPresignedObjectUrlArgs;
import io.minio.MinioClient;
import io.minio.http.Method;
import lombok.SneakyThrows;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.UUID;
import java.util.concurrent.TimeUnit;

/**
 * MinIO 预签名直传（本地/自建 S3 兼容）。生产可替换为阿里云 OSS / 腾讯云 COS 实现。
 */
@Component
@ConditionalOnProperty(name = "app.oss.provider", havingValue = "minio")
public class MinioOssService implements OssService {

    private final MinioClient client;
    private final String endpoint;
    private final String bucket;

    public MinioOssService(MinioClient client, org.springframework.core.env.Environment env) {
        this.client = client;
        this.endpoint = env.getProperty("app.oss.minio.endpoint");
        this.bucket = env.getProperty("app.oss.minio.bucket", "repairhub");
    }

    @Override
    @SneakyThrows
    public PresignResult presignUpload(String fileName, String contentType) {
        String suffix = fileName.contains(".")
                ? fileName.substring(fileName.lastIndexOf('.'))
                : "";
        String objectKey = "upload/" + UUID.randomUUID() + suffix;
        String uploadUrl = client.getPresignedObjectUrl(GetPresignedObjectUrlArgs.builder()
                .method(Method.PUT)
                .bucket(bucket)
                .object(objectKey)
                .expiry(10, TimeUnit.MINUTES)
                .build());
        String objectUrl = endpoint + "/" + bucket + "/" + objectKey;
        return new PresignResult(uploadUrl, objectUrl, objectKey);
    }
}
