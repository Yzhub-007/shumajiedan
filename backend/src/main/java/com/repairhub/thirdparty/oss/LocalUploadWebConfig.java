package com.repairhub.thirdparty.oss;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Paths;

/**
 * mock 上传模式下，把本地上传目录暴露为静态资源 /uploads/**（SecurityConfig 已放行）。
 */
@Configuration
@ConditionalOnProperty(name = "app.oss.provider", havingValue = "mock", matchIfMissing = true)
public class LocalUploadWebConfig implements WebMvcConfigurer {

    @Value("${app.oss.local-dir:./data/uploads}")
    private String localDir;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String location = Paths.get(localDir).toAbsolutePath().normalize().toUri().toString();
        registry.addResourceHandler("/uploads/**").addResourceLocations(location);
    }
}
