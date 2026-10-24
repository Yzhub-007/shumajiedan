package com.repairhub.thirdparty.oss;

/**
 * 对象存储适配器：客户端拿预签名 URL 直传（App 不经后端转发文件）。
 */
public interface OssService {

    PresignResult presignUpload(String fileName, String contentType);

    record PresignResult(String uploadUrl, String objectUrl, String objectKey) {
    }
}
