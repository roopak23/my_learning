package com.acn.dm.common.utils.error.handlers;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.validation.BeanPropertyBindingResult;

import com.acn.dm.common.config.rest.error.FieldValidationError;
import com.acn.dm.common.utils.error.AbstractHandleException;
import com.acn.dm.common.utils.rest.output.error.ApiBadRequest;

public class HandleBeanPropertyBindingResult extends AbstractHandleException<BeanPropertyBindingResult,ApiBadRequest> {

	public HandleBeanPropertyBindingResult() {
		super(BeanPropertyBindingResult.class);
	}

	@Override
	public ApiBadRequest doHandle(BeanPropertyBindingResult ex, Exception parent) {
		// @formatter:off
		List<FieldValidationError> errors = ex
				.getFieldErrors()
				.parallelStream()
				.map(e -> FieldValidationError.builder().field(e.getField()).message(e.getDefaultMessage()).build())
				.collect(Collectors.toList());
		// @formatter:on
		return new ApiBadRequest(parent.getMessage(), errors);
	}

}