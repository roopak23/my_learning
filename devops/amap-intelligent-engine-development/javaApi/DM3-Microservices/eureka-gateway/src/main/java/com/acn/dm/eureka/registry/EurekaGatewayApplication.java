package com.acn.dm.eureka.registry;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.netflix.eureka.server.EnableEurekaServer;


@EnableEurekaServer
@SpringBootApplication
public class EurekaGatewayApplication {

	public static void main(String[] args) {
		SpringApplication.run(EurekaGatewayApplication.class, args).getEnvironment();
	}

}
