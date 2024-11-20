package com.acn.dm.common.config.aspect.logger.rest;

import jakarta.annotation.PostConstruct;
import java.lang.reflect.Method;


import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.GetMapping;

import com.acn.dm.common.Utility;

/**
 * @author Shivani Chaudhary
 */
@Aspect
@Component
public class GetRequestLogger extends AbstractRequestLogger {

	@Override
	protected String getRequestMethod() {
		return "GET";
	}

	@PostConstruct
	public void logInfo() {
		Utility.getLogger(GetRequestLogger.class).info("Aspect Registration : GetRequestLogger");
	}

	@Override
	@Pointcut("@annotation(org.springframework.web.bind.annotation.GetMapping)")
	protected void mappingAction() {
	}

	@Override
	protected String[] mappingMethodUrlResolver(Method method) {
		return method.getAnnotation(GetMapping.class).value();
	}

}
