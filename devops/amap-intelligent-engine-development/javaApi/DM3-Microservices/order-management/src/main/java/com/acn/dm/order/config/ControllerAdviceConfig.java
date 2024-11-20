package com.acn.dm.order.config;

import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.RestController;

import com.acn.dm.common.config.rest.error.handler.AbstractApiErrorExceptionHandler;
import com.acn.dm.order.OrderManagementApplication;

/**
 * @author Shivani Chaudhary
 *
 */
@ControllerAdvice(annotations = RestController.class, basePackageClasses = OrderManagementApplication.class)
public class ControllerAdviceConfig extends AbstractApiErrorExceptionHandler {

}
