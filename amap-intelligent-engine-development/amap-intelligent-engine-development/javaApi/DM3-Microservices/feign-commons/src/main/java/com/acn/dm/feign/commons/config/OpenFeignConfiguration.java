package com.acn.dm.feign.commons.config;

import jakarta.annotation.PostConstruct;
import java.util.Arrays;
import java.util.List;


import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Scope;

import com.acn.dm.feign.commons.request.interceptor.KeyCloakCurrentUserTokenExtractorAuthenticationInterceptor;

import feign.Feign;
import feign.Logger;
import feign.RequestInterceptor;
import feign.codec.ErrorDecoder;
import lombok.extern.slf4j.Slf4j;

/**
 * @author Shivani Chaudhary
 */
@Slf4j
@Configuration
public class OpenFeignConfiguration {

  @PostConstruct
  public void logInfo() {
    log.warn("Register OpenFeignConfiguration");
  }

  @Bean
  Logger.Level feignLoggerLevel() {
    return Logger.Level.FULL;
  }

  @Bean
  @Scope("prototype")
  public Feign.Builder feignBuilder() {
    log.warn("Register Default feignBuilder");
    return Feign.builder().requestInterceptor(requestInterceptor());
  }

  @Bean
  public ErrorDecoder errorDecoder() {
    log.warn("Register Default error encoder");
    return new CustomErrorDecoder();
  }

  @Bean
  public RequestInterceptor requestInterceptor() {
    log.warn("KeyCloakCurrentUserTokenExtractorAuthenticationInterceptor");
    return new KeyCloakCurrentUserTokenExtractorAuthenticationInterceptor();
  }

}
