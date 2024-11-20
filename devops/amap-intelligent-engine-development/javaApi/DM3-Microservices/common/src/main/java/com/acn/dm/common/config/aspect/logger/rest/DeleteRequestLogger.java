package com.acn.dm.common.config.aspect.logger.rest;

import jakarta.annotation.PostConstruct;
import java.lang.reflect.Method;


import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.DeleteMapping;

import com.acn.dm.common.Utility;

/**
 * @author Shivani Chaudhary
 *
 */
@Aspect
@Component
public class DeleteRequestLogger extends AbstractRequestLogger {

	@Override
	protected String getRequestMethod() {
		return "DELETE";
	}

	@PostConstruct
	public void logInfo() {
		Utility.getLogger(DeleteRequestLogger.class).info("Aspect Registration : DeleteRequestLogger");
	}

	@Override
	@Pointcut("@annotation(org.springframework.web.bind.annotation.DeleteMapping)")
	protected void mappingAction() {}
	
	@Override
	protected String[] mappingMethodUrlResolver(Method method) {
		return method.getAnnotation(DeleteMapping.class).value();
	}

}
