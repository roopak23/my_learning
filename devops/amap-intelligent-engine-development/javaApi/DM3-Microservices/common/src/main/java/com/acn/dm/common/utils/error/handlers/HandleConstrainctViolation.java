package com.acn.dm.common.utils.error.handlers;

import jakarta.validation.ConstraintViolationException;
import java.util.List;
import java.util.stream.Collectors;


import com.acn.dm.common.config.rest.error.FieldValidationError;
import com.acn.dm.common.utils.error.AbstractHandleException;
import com.acn.dm.common.utils.rest.output.error.ApiBadRequest;

public class HandleConstrainctViolation extends AbstractHandleException<ConstraintViolationException,ApiBadRequest> {

	
	public HandleConstrainctViolation() {
		super(ConstraintViolationException.class);
	}

	@Override
	public ApiBadRequest doHandle(ConstraintViolationException ex, Exception parent) {
		// @formatter:off
		List<FieldValidationError> errors = ex
			.getConstraintViolations()
			.parallelStream()
			.map(e -> FieldValidationError.builder().field(e.getPropertyPath().toString()).message(e.getMessage()).build())
			.collect(Collectors.toList());
		// @formatter:on
		return new ApiBadRequest(parent.getMessage(), errors);
	}

}