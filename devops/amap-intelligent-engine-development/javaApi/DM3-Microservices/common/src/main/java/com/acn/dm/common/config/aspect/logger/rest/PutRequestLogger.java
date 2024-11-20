package com.acn.dm.common.config.aspect.logger.rest;

import jakarta.annotation.PostConstruct;
import java.lang.reflect.Method;


import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.PutMapping;

import com.acn.dm.common.Utility;

/**
 * @author Shivani Chaudhary
 *
 */
@Component
@Aspect
public class PutRequestLogger extends AbstractRequestLogger {


	@PostConstruct
	public void logInfo() {
		Utility.getLogger(PutRequestLogger.class).info("Aspect Registration : PutRequestLogger");
	}

	@Override
	@Pointcut("@annotation(org.springframework.web.bind.annotation.PutMapping)")
	protected void mappingAction() {}
	
	@Override
	protected String[] mappingMethodUrlResolver(Method method) {
		return method.getAnnotation(PutMapping.class).value();
	}
	
	/**
	 * @return
	 */
	@Override
	protected String getRequestMethod() {
		return "PUT";
	}
}
