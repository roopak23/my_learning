package com.acn.dm.inventory.config;

import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.RestController;

import com.acn.dm.common.config.rest.error.handler.AbstractApiErrorExceptionHandler;
import com.acn.dm.inventory.InventoryManagementApplication;

/**
 * @author Shivani Chaudhary
 *
 */
@ControllerAdvice(annotations = RestController.class, basePackageClasses = InventoryManagementApplication.class)
public class ControllerAdviceConfig extends AbstractApiErrorExceptionHandler {

}
