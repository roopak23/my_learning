package com.acn.dm.inventory;

import static com.acn.dm.common.constants.PackagesConstants.ROOT_BASE_PACKAGE;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.core.env.Environment;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

import com.acn.dm.common.utils.LogAppInfo;

@EnableDiscoveryClient
@SpringBootApplication
@ComponentScan(basePackages = ROOT_BASE_PACKAGE)
@EnableJpaRepositories(basePackages = ROOT_BASE_PACKAGE)
@EntityScan(basePackages = ROOT_BASE_PACKAGE)
public class InventoryManagementApplication {

	public static void main(String[] args) {
		Environment env = SpringApplication.run(InventoryManagementApplication.class, args).getEnvironment();
		LogAppInfo.logInfo(env);
	}

}