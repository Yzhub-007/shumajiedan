package com.repairhub.thirdparty.oss;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * 开发用 Mock：返回占位地址，不做真实上传。
 */
@Component
@ConditionalOnProperty(name = "app.oss.provider", havingValue = "mock", matchIfMissing = true)
public class MockOssService implements OssService {

    @Override
    public PresignResult presignUpload(String fileName, String contentType) {
        String objectKey = "mock/" + UUID.randomUUID() + "-" + fileName;
        return new PresignResult("/uploads/dev-only/" + objectKey,
                "http://localhost:8080/uploads/dev-only/" + objectKey, objectKey);
    }
}
