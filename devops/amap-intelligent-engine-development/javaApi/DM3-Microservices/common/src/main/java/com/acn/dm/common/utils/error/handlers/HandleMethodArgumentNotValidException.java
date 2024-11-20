package com.acn.dm.common.utils.error.handlers;

import java.util.ArrayList;
import java.util.List;

import org.springframework.validation.FieldError;
import org.springframework.validation.ObjectError;
import org.springframework.web.bind.MethodArgumentNotValidException;

import com.acn.dm.common.config.rest.error.FieldValidationError;
import com.acn.dm.common.utils.error.AbstractHandleException;
import com.acn.dm.common.utils.rest.output.error.ApiBadRequest;

/**
 * @author Shivani Chaudhary
 *
 */
public class HandleMethodArgumentNotValidException extends AbstractHandleException<MethodArgumentNotValidException,ApiBadRequest>{

	public HandleMethodArgumentNotValidException() {
		super(MethodArgumentNotValidException.class);
	}
	
	@Override
	public ApiBadRequest doHandle(MethodArgumentNotValidException ex, Exception parent) {
		List<FieldValidationError> errors = new ArrayList<>();
		for (FieldError error : ex.getBindingResult().getFieldErrors()) {
			errors.add(FieldValidationError.builder().message(error.getDefaultMessage()).field(error.getField()).build());
		}
		for (ObjectError error : ex.getBindingResult().getGlobalErrors()) {
			errors.add(FieldValidationError.builder().message(error.getDefaultMessage()).field(error.getObjectName()).build());
		}
		return new ApiBadRequest(ex.getLocalizedMessage(), errors);
	}
	
	
}
