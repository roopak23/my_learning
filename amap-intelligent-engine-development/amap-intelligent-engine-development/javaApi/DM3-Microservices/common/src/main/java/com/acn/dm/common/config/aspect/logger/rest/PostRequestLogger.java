package com.acn.dm.common.config.aspect.logger.rest;

import jakarta.annotation.PostConstruct;
import java.lang.reflect.Method;


import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.PostMapping;

import com.acn.dm.common.Utility;

/**
 * @author Shivani Chaudhary
 */
@Component
@Aspect
public class PostRequestLogger extends AbstractRequestLogger {

	@Override
	protected String getRequestMethod() {
		return "POST";
	}

	@PostConstruct
	public void logInfo() {
		Utility.getLogger(PostRequestLogger.class).info("Aspect Registration : PostRequestLogger");
	}

	@Override
	@Pointcut("@annotation(org.springframework.web.bind.annotation.PostMapping)")
	public void mappingAction() {
	}

	@Override
	protected String[] mappingMethodUrlResolver(Method method) {
		return method.getAnnotation(PostMapping.class).value();
	}
}
