package com.acn.dm.common.utils.rest.output.success;

import org.springframework.http.HttpStatus;

import com.acn.dm.common.utils.rest.output.ApiResult;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Generic Success Response")
public class ApiSuccess<T> extends ApiResult<T>{
	
	public static final String ERROR_TYPE = "Success";
	public static final int ERROR_STATUS = 200;
	
	public ApiSuccess(String message, T body) {
		super(message,ERROR_TYPE,HttpStatus.OK,body);
	}
	
	public ApiSuccess(T body) {
		this(ERROR_TYPE, body);
	}
	
}