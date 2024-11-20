package com.acn.dm.common.config.rest.error.handler;

import jakarta.annotation.PostConstruct;
import jakarta.validation.ConstraintViolationException;
import jakarta.validation.ValidationException;
import java.util.Objects;



import org.apache.commons.lang3.exception.ExceptionUtils;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.util.NestedServletException;

import com.acn.dm.common.Utility;
import com.acn.dm.common.utils.error.HandleBadRequestChain;
import com.acn.dm.common.utils.rest.output.ApiResult;
import com.acn.dm.common.utils.rest.output.error.ApiBadRequest;
import com.acn.dm.common.utils.rest.output.error.ApiGenericError;
import com.acn.dm.common.utils.rest.output.error.ApiGenericErrorBody;

public abstract class AbstractApiErrorExceptionHandler {

	@PostConstruct
	public void logInfo() {
		Utility.getLogger(getClass()).info("AbstractApiErrorExceptionHandler registred");
	}

	@ExceptionHandler({ ValidationException.class, HttpMessageNotReadableException.class, MethodArgumentNotValidException.class, ConstraintViolationException.class })
	public ResponseEntity<Object> invalidField(Exception exParent) {

		HandleBadRequestChain handler = new HandleBadRequestChain();

		if (handler.canHandle(exParent)) {
			ApiBadRequest badRequest = handler.process(exParent);
			if (!Objects.isNull(badRequest)) {
				return badRequest.toResponseObject();
			}
		}
		return new ApiGenericError(new ApiGenericErrorBody(exParent.getMessage().toString())).toResponseObject();
	}

	@ExceptionHandler(NestedServletException.class)
	public ResponseEntity<Object> handleError(NestedServletException exParent) {
		AssertionError ex = ExceptionUtils.getThrowableList(exParent).stream().filter(AssertionError.class::isInstance).map(AssertionError.class::cast).findFirst().orElseGet(null);
		String message = exParent.getMessage();
		if (!Objects.isNull(ex)) {
			message = ex.getMessage();
		}
		return new ApiGenericError(new ApiGenericErrorBody(message.toString())).toResponseObject();
	}

	@ExceptionHandler(Exception.class)
	public ResponseEntity<ApiResult<ApiGenericErrorBody>> handleException(Exception ex) {
		return new ApiGenericError(ex.getMessage(), null).toResponse();
	}

  @ExceptionHandler(ResponseStatusException.class)
  public ResponseEntity<ApiResult<ApiGenericErrorBody>> handleInvalidPayload(ResponseStatusException ex) {
    return new ApiResult<ApiGenericErrorBody>(
      "AdSlot list empty after exclusion process",
      "Invalid payload",
      HttpStatus.BAD_REQUEST,
      null
      ).toResponse();
  }

}
