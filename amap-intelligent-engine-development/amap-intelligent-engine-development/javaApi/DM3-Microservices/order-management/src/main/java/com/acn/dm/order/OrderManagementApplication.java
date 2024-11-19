package com.acn.dm.order;

import static com.acn.dm.common.constants.PackagesConstants.ROOT_BASE_PACKAGE;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.core.env.Environment;

import com.acn.dm.common.utils.LogAppInfo;
import org.springframework.retry.annotation.EnableRetry;

@EnableFeignClients
@EnableDiscoveryClient
@SpringBootApplication
@EnableRetry()
@ComponentScan(basePackages = ROOT_BASE_PACKAGE)
public class OrderManagementApplication {

	public static void main(String[] args) {
		Environment env = SpringApplication.run(OrderManagementApplication.class, args).getEnvironment();
		LogAppInfo.logInfo(env);
	}

}