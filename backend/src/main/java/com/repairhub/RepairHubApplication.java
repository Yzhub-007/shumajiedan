package com.repairhub;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

/**
 * 机器报修接单平台后端 —— 模块化单体。
 * 模块边界见 docs/ARCHITECTURE.md：common / auth / user / order / dispatch / notify / payment / admin / thirdparty
 */
@SpringBootApplication
@ConfigurationPropertiesScan
public class RepairHubApplication {

    public static void main(String[] args) {
        SpringApplication.run(RepairHubApplication.class, args);
    }
}
