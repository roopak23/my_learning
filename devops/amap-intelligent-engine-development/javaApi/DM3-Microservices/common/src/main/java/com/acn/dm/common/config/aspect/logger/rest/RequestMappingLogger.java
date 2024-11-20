package com.acn.dm.common.config.aspect.logger.rest;

import jakarta.annotation.PostConstruct;
import java.lang.reflect.Method;


import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.RequestMapping;

/**
 * @author Shivani Chaudhary
 *
 */
@Component
@Aspect
public class RequestMappingLogger extends AbstractRequestLogger {

	@Override
	protected String getRequestMethod() {
		return "";
	}

	@PostConstruct
	public void logInfo() {
		LoggerFactory.getLogger(RequestMappingLogger.class).info("Aspect Registration : RequestMappingLogger");
	}

	@Override
	@Pointcut("@annotation(org.springframework.web.bind.annotation.RequestMapping)")
	public void mappingAction() {
	}

	@Override
	protected String[] mappingMethodUrlResolver(Method method) {
		return method.getAnnotation(RequestMapping.class).value();
	}
}
