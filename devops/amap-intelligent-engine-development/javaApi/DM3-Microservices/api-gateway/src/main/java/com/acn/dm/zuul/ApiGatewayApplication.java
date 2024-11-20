package com.acn.dm.zuul;

import static com.acn.dm.common.constants.DMConstants.AUTH_ACTUATOR_CONFIG_GENERAL;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.netflix.zuul.EnableZuulProxy;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.ComponentScans;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

import com.acn.dm.common.utils.LogAppInfo;
import com.acn.dm.zuul.config.ProxyFilter;



@EnableZuulProxy
@SpringBootApplication
@EnableDiscoveryClient
@Controller
@ComponentScans({
	@ComponentScan(basePackages = AUTH_ACTUATOR_CONFIG_GENERAL),
	@ComponentScan(basePackages = "com.acn.dm.zuul")
})
public class ApiGatewayApplication {
	
	public static void main(String[] args) {
		Environment env = SpringApplication.run(ApiGatewayApplication.class, args).getEnvironment();
		LogAppInfo.logInfo(env);
	}

	@Bean
	public ProxyFilter filter() {
		return new ProxyFilter();
	}
	
	@RequestMapping("/login")
	public String redirectToRoot() {
		return "forward:/";
	}
	
	@RequestMapping({"","/"})
	public String redirectToGui() {
		return "forward:/web/";
	}
	
}