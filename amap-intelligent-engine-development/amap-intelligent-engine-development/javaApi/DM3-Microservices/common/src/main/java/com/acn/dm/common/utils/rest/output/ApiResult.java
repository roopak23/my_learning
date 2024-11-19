package com.acn.dm.common.utils.rest.output;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import com.acn.dm.common.utils.rest.output.error.ApiBadRequest;
import com.acn.dm.common.utils.rest.output.error.ApiGenericError;
import com.acn.dm.common.utils.rest.output.success.ApiSuccess;
import com.fasterxml.jackson.annotation.JsonIgnore;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class ApiResult<T> {

	@Schema(defaultValue = "Result Message", requiredMode = Schema.RequiredMode.REQUIRED)
	private String message;
	
	@Schema(defaultValue = "Result type ( " + ApiSuccess.ERROR_TYPE + ", " + ApiBadRequest.ERROR_TYPE + ", " + ApiGenericError.ERROR_TYPE + ", ...)", requiredMode = Schema.RequiredMode.REQUIRED)
	private String type;
	
	@JsonIgnore
	private HttpStatus status;
	
	@Schema(defaultValue = "Result body", requiredMode = Schema.RequiredMode.REQUIRED)
	private T body;
	
	
	public ResponseEntity<ApiResult<T>> toResponse(){
		return ResponseEntity.status(getStatus()).body(this);
	}
		
	public ResponseEntity<Object> toResponseObject(){
		return ResponseEntity.status(getStatus()).body(this);
	}
		
	public ResponseEntity<T> bodyToResponse(){
		return ResponseEntity.status(getStatus()).body(getBody());
	}
	
	public ApiResult(String message, String type, HttpStatus status, T body) {
		super();
		this.message = message;
		this.type = type;
		this.status = status;
		this.body = body;
	}
}
