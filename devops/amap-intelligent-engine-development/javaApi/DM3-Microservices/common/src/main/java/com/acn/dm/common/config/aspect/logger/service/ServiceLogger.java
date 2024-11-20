package com.acn.dm.common.config.aspect.logger.service;

import jakarta.annotation.PostConstruct;
import java.lang.reflect.Method;


import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.AfterReturning;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.aspectj.lang.annotation.Pointcut;
import org.aspectj.lang.reflect.MethodSignature;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import com.acn.dm.common.Utility;

/**
 * @author Shivani Chaudhary
 *
 */
@Component
@Aspect
public class ServiceLogger {

	@PostConstruct
	public void lofInfo() {
		LoggerFactory.getLogger(ServiceLogger.class).info("Aspect Registration : ServiceLogger");
	}
	
	@Pointcut("@annotation(org.springframework.stereotype.Service)")
	public void annotatedByService() {}
	
	@Pointcut("execution(public * *(..))")
	public void publicMethodExecution() {}
	
	
	@Before("annotatedByService() && publicMethodExecution()")
	public void logAction(JoinPoint joinPoint) {
		Class<?> clazz = joinPoint.getTarget().getClass();
		Logger log = LoggerFactory.getLogger(clazz);

		MethodSignature methodSignature = (MethodSignature) joinPoint.getSignature();
		Method method = methodSignature.getMethod();
		StringBuilder message = new StringBuilder();
		message.append("Enter In ").append(method.getName()).append(" With Args: ").append(joinPoint.getArgs());
		log.info(message.toString());
	}
	
	@AfterReturning(pointcut = "annotatedByService() && publicMethodExecution()", returning = "result")
	public void logResult(JoinPoint joinPoint, Object result) {
		try {
			Class<?> clazz = joinPoint.getTarget().getClass();
			Utility.getLogger(clazz).info("<-- Result: {}", result);
		} catch (Exception e) {
			Utility.getLogger(this.getClass()).warn("Error on aspect logger: {}", e.getMessage());
		}
	}
}
