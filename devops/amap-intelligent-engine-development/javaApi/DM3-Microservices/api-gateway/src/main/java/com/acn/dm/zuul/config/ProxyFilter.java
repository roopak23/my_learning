package com.acn.dm.zuul.config;


import lombok.extern.slf4j.Slf4j;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.server.reactive.ServerHttpRequest;

@Slf4j
@Configuration
public class ProxyFilter {

    public boolean shouldFilter() {
        return true;
    }

    @Bean
    public GlobalFilter customGlobalFilter() {
        return (exchange, chain) -> {
            ServerHttpRequest request = exchange.getRequest();
            HttpHeaders headers = request.getHeaders();
            String method = request.getMethod().toString();
            String url = request.getURI().toString();

            // Log request information
            log.info(String.format("%s request to %s", method, url));

            // Add X-HOST header
            String remoteHost = request.getRemoteAddress().getAddress().getHostAddress();
            headers.add("X-HOST", remoteHost);

            return chain.filter(exchange);
        };
    }

}