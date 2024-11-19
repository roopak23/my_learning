package com.acn.dm.common.utils.error.handlers;

import java.util.List;
import java.util.stream.Collectors;

import org.apache.commons.lang3.exception.ExceptionUtils;
import org.springframework.http.converter.HttpMessageNotReadableException;

import com.acn.dm.common.utils.error.AbstractHandleException;
import com.acn.dm.common.utils.rest.output.error.ApiBadRequest;
import com.fasterxml.jackson.databind.exc.UnrecognizedPropertyException;

/**
 * @author Shivani Chaudhary
 *
 */
public class HandleHttpMessageNotReadableException extends  AbstractHandleException<HttpMessageNotReadableException,ApiBadRequest>{

	public HandleHttpMessageNotReadableException() {
		super(HttpMessageNotReadableException.class);
	}

	@Override
	public ApiBadRequest doHandle(HttpMessageNotReadableException ex, Exception parent) {
		UnrecognizedPropertyException jsonEx = ExceptionUtils.getThrowableList(ex).stream().filter(UnrecognizedPropertyException.class::isInstance).map(UnrecognizedPropertyException.class::cast)
				.findFirst().orElse(null);
		if (null != jsonEx) {
			String invalidField = jsonEx.getPropertyName();
			List<String> knownFields = jsonEx.getKnownPropertyIds().parallelStream().map(e -> e.toString()).collect(Collectors.toList());
			if (null == knownFields || knownFields.size() < 1) {
				return new ApiBadRequest("No property mapped on " + jsonEx.getReferringClass().getSimpleName(), null);
			}
			return ApiBadRequest.unknown(invalidField, knownFields);
		}
		return new ApiBadRequest(parent.getMessage(), null);
	}


}
