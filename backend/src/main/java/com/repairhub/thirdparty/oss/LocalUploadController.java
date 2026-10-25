package com.repairhub.thirdparty.oss;

import com.repairhub.common.exception.BizException;
import com.repairhub.common.exception.ErrorCode;
import com.repairhub.common.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;
import java.util.UUID;

/**
 * 开发环境直传端点（app.oss.provider=mock 时生效）：multipart 上传落盘，
 * 通过 /uploads/** 静态访问。生产环境请切换 minio/云 OSS 预签名直传（POST /api/upload/presign）。
 */
@Slf4j
@Tag(name = "文件上传（开发）")
@RestController
@RequestMapping("/api/upload")
@ConditionalOnProperty(name = "app.oss.provider", havingValue = "mock", matchIfMissing = true)
public class LocalUploadController {

    @Value("${app.oss.local-dir:./data/uploads}")
    private String localDir;

    @Operation(summary = "上传文件，返回可访问 URL")
    @PostMapping
    public ApiResponse<Map<String, String>> upload(@RequestParam("file") MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BizException(ErrorCode.PARAM_ERROR, "文件不能为空");
        }
        String original = file.getOriginalFilename() == null ? "file" : file.getOriginalFilename();
        String ext = original.contains(".")
                ? original.substring(original.lastIndexOf('.')).toLowerCase()
                : "";
        String fileName = UUID.randomUUID().toString().replace("-", "") + ext;
        try {
            Path dir = Paths.get(localDir).toAbsolutePath();
            Files.createDirectories(dir);
            file.transferTo(dir.resolve(fileName).toFile());
        } catch (IOException e) {
            log.error("文件保存失败", e);
            throw new BizException(ErrorCode.SYSTEM_ERROR, "文件保存失败");
        }
        String url = "/uploads/" + fileName;
        return ApiResponse.ok(Map.of("url", url, "fileName", fileName));
    }
}
