package com.acn.dm.order.service.impl;

import java.util.concurrent.ExecutorService;
import org.springframework.beans.factory.config.ConfigurableBeanFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

@Configuration
public class ExecutorConfig {

    @Bean(ConfigurableBeanFactory.SCOPE_SINGLETON)
    public ExecutorService getExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(1);
        executor.setMaxPoolSize(15);
        executor.setQueueCapacity(Integer.MAX_VALUE);
        executor.setThreadNamePrefix("HandlerThread-");
        executor.initialize();
        return executor.getThreadPoolExecutor();
    }

}
