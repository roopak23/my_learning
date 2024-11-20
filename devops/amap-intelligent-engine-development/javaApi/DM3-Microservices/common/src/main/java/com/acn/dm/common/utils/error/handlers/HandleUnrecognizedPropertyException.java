package com.acn.dm.common.utils.error.handlers;

import java.util.List;
import java.util.stream.Collectors;

import com.acn.dm.common.utils.error.AbstractHandleException;
import com.acn.dm.common.utils.rest.output.error.ApiBadRequest;
import com.fasterxml.jackson.databind.exc.UnrecognizedPropertyException;

public class HandleUnrecognizedPropertyException extends AbstractHandleException<UnrecognizedPropertyException,ApiBadRequest> {

	public HandleUnrecognizedPropertyException() {
		super(UnrecognizedPropertyException.class);
	}

	@Override
	public ApiBadRequest doHandle(UnrecognizedPropertyException ex, Exception parent) {
		String       invalidField = ex.getPropertyName();
		List<String> knownFields  = ex.getKnownPropertyIds().parallelStream().map(e -> e.toString()).collect(Collectors.toList());
		if (null == knownFields || knownFields.size() < 1) {
			return new ApiBadRequest("No property mapped on " + ex.getReferringClass().getSimpleName());
		}
		return ApiBadRequest.unknown(invalidField, knownFields);

	}

}