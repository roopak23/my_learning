package com.acn.dm.common.config.aspect.logger.rest;

import java.lang.reflect.Method;

import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.AfterReturning;
import org.aspectj.lang.annotation.AfterThrowing;
import org.aspectj.lang.annotation.Before;
import org.aspectj.lang.reflect.CodeSignature;
import org.aspectj.lang.reflect.MethodSignature;
import org.springframework.web.bind.annotation.RequestMapping;

import com.acn.dm.common.Utility;

/**
 * @author Shivani Chaudhary
 *
 */
public abstract class AbstractRequestLogger {

	protected abstract String getRequestMethod();

	protected abstract void mappingAction();

	protected abstract String[] mappingMethodUrlResolver(Method method);

	@Before("mappingAction()")
	public void logAction(JoinPoint joinPoint) {
		try {
			Class<?> clazz = joinPoint.getTarget().getClass();
			MethodSignature methodSignature = (MethodSignature) joinPoint.getSignature();
			Method method = methodSignature.getMethod();
			String url = getRequestUrl(method, clazz);
			String payload = getPayload(joinPoint);
			Utility.getLogger(clazz).info("--> {} {} with payload {}",getRequestMethod(), url , payload);
		} catch (Exception e) {
			Utility.getLogger(this.getClass()).warn("Error on aspect logger: {}", e.getMessage());
		}
	}
	
	@AfterReturning(pointcut = "mappingAction()", returning = "result")
	public void logResult(JoinPoint joinPoint, Object result) {
		try {
			Class<?> clazz = joinPoint.getTarget().getClass();
			Utility.getLogger(clazz).info("<-- Result: {}", result);
		} catch (Exception e) {
			Utility.getLogger(this.getClass()).warn("Error on aspect logger: {}", e.getMessage());
		}
	}
	
	@AfterThrowing(pointcut = "mappingAction()", throwing = "result")
	public void logErrorResult(JoinPoint joinPoint, Throwable result) {
		try {
			Class<?> clazz = joinPoint.getTarget().getClass();
			Utility.getLogger(clazz).error("<-- Result Error: {}", result.getMessage());
		} catch (Exception e) {
			Utility.getLogger(this.getClass()).warn("Error on aspect logger: {}", e.getMessage());
		}
	}
	private String getRequestUrl(Method method, Class<?> clazz) {
		RequestMapping requestMapping = (RequestMapping) clazz.getAnnotation(RequestMapping.class);
		return getMappingUrl(requestMapping, method);
	}

	private String getPayload(JoinPoint joinPoint) {
		CodeSignature signature = (CodeSignature) joinPoint.getSignature();
		StringBuilder builder = new StringBuilder();
		Object[] args = joinPoint.getArgs();
		if (null != signature.getParameterNames() && signature.getParameterNames().length != 0) {
			for (int i = 0; i < joinPoint.getArgs().length; i++) {
				String parameterName = signature.getParameterNames()[i];
					builder.append(parameterName);
					builder.append(": ");
					builder.append(null != args[i] ? args[i].toString() : null);
					builder.append(", ");
			}
		}
		return builder.toString();
	}

	private String getMappingUrl(RequestMapping requestMapping, Method method) {
		String baseUrl = null != requestMapping ? getUrl(requestMapping.value()) : "";
		String endpoint = getUrl(mappingMethodUrlResolver(method));

		return baseUrl + endpoint;
	}

	private String getUrl(String[] urls) {
		if (urls.length == 0)
			return "";
		else
			return urls[0];
	}

}
