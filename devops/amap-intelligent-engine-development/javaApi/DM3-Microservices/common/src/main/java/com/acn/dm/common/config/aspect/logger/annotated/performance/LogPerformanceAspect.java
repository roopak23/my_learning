package com.acn.dm.common.config.aspect.logger.annotated.performance;


import jakarta.annotation.PostConstruct;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.stereotype.Component;

import lombok.extern.slf4j.Slf4j;

/**
 * @author Shivani Chaudhary
 *
 */
@Component
@Aspect
@Slf4j
public class LogPerformanceAspect {

	@PostConstruct
	public void logInfo() {
		log.info("Aspect Registration : LogPerformanceAspect");
	}
	
	@Around("@annotation(LogPerformance)")
	public Object logExecutionTime(ProceedingJoinPoint joinPoint) throws Throwable {
	    long start = System.currentTimeMillis();
	 
	    Object proceed = joinPoint.proceed();
	 
	    long executionTime = System.currentTimeMillis() - start;
	 
	    log.info(joinPoint.getSignature() + " executed in " + executionTime + "ms");
	    return proceed;
	}
	
}
