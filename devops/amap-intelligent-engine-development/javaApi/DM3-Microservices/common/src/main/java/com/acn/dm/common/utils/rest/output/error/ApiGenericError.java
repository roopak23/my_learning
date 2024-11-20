package com.acn.dm.common.utils.rest.output.error;

import org.springframework.http.HttpStatus;

import com.acn.dm.common.utils.rest.output.ApiResult;

public class ApiGenericError extends ApiResult<ApiGenericErrorBody> {
	
	public static final String ERROR_TYPE = "Generic Error";
	public static final int ERROR_STATUS = 500;
	
	public ApiGenericError(String message, ApiGenericErrorBody body) {
		super(message, ERROR_TYPE, HttpStatus.INTERNAL_SERVER_ERROR, body);
	}

	public ApiGenericError(ApiGenericErrorBody body) {
		this(ERROR_TYPE, body);
	}
}