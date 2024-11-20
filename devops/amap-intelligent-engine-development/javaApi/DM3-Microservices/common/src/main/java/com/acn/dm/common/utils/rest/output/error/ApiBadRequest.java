package com.acn.dm.common.utils.rest.output.error;

import java.text.MessageFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;

import org.springframework.http.HttpStatus;

import com.acn.dm.common.config.rest.error.FieldValidationError;
import com.acn.dm.common.utils.rest.output.ApiResult;

public class ApiBadRequest extends ApiResult<List<FieldValidationError>> {

	public static final String ERROR_TYPE = "Validation Error";
	public static final int ERROR_STATUS = 400;

	public ApiBadRequest(List<FieldValidationError> body) {
		this(ERROR_TYPE, body);
	}
	
	public ApiBadRequest(String message) {
		super(message, ERROR_TYPE, HttpStatus.BAD_REQUEST, new ArrayList<>());
	}

	public ApiBadRequest(String message, List<FieldValidationError> body) {
		super(message, ERROR_TYPE, HttpStatus.BAD_REQUEST, body);
	}
	
	public static ApiBadRequest unknown(String field, Collection<String> knownFields) {
		String MESSAGE_TEMPLATE = "Unknown field {0}";
		String wrapperField = new StringBuilder().append("\"").append(field).append("\"").toString();
		String message = MessageFormat.format(MESSAGE_TEMPLATE, null != field ? wrapperField : "error");
		return new ApiBadRequest(message, Arrays.asList(FieldValidationError.builder().field(field).knownFields(knownFields).message(message).build()));
	}

}