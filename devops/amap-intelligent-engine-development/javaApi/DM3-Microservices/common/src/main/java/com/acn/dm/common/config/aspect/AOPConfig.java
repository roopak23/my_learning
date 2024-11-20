package com.acn.dm.common.config.aspect;


import jakarta.annotation.PostConstruct;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.EnableAspectJAutoProxy;

import com.acn.dm.common.Utility;

/**
 * @author Shivani Chaudhary
 */
@Configuration
@EnableAspectJAutoProxy
public class AOPConfig {
	@PostConstruct
	public void logInfo() {
		Utility.getLogger(getClass()).info("AOP configurated");
	}
}
