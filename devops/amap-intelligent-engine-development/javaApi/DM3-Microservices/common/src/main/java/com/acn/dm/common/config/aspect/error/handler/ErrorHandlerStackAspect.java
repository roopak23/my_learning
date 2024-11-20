package com.acn.dm.common.config.aspect.error.handler;


import jakarta.annotation.PostConstruct;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.aspectj.lang.annotation.Pointcut;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import lombok.extern.slf4j.Slf4j;

/**
 * @author Shivani Chaudhary
 *
 */
@Slf4j
@Aspect
@Component
@ConditionalOnProperty(name = ErrorHandlerStackAspect.ASPECT_ENABLED_PROPERTY, havingValue = "false", matchIfMissing = true)
public class ErrorHandlerStackAspect {
	
	public static final String ASPECT_ENABLED_PROPERTY = "application.aspect.ignore.error-stack";

	@PostConstruct
	public void logInfo() {
		log.info("Aspect Registration : ErrorHandlerStackAspect");
	}
	
	@Pointcut("execution(* com.acn.dm.common.config.rest.error.handler.AbstractApiErrorExceptionHandler.*(..))")
    public void ControllerAdviceExecutionPointcut() {}
	
	@Before("ControllerAdviceExecutionPointcut()")
	public void printStack(JoinPoint joinPoint) {
		Object ex = joinPoint.getArgs()[0];
		if(Exception.class.isAssignableFrom(ex.getClass())) {
			log.error("{}",Exception.class.cast(ex).getMessage());
		}else {
			log.warn("No error found on {} with args {}",joinPoint.getSignature(), joinPoint.getArgs());
		}
	}
	
}
