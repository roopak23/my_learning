package com.acn.dm.common.utils.error;

import com.acn.dm.common.utils.ActionChain;
import com.acn.dm.common.utils.ActionChainContainer;
import com.acn.dm.common.utils.error.handlers.HandleBeanPropertyBindingResult;
import com.acn.dm.common.utils.error.handlers.HandleConstrainctViolation;
import com.acn.dm.common.utils.error.handlers.HandleHttpMessageNotReadableException;
import com.acn.dm.common.utils.error.handlers.HandleMethodArgumentNotValidException;
import com.acn.dm.common.utils.error.handlers.HandleUnrecognizedPropertyException;
import com.acn.dm.common.utils.rest.output.error.ApiBadRequest;

/**
 * @author Shivani Chaudhary
 */
public class HandleBadRequestChain implements ActionChain<Exception,ApiBadRequest>{

	private final ActionChainContainer<Exception,ApiBadRequest> container = new ActionChainContainer<Exception,ApiBadRequest>()
			.add(new HandleBeanPropertyBindingResult())
			.add(new HandleConstrainctViolation())
			.add(new HandleUnrecognizedPropertyException())
			.add(new HandleMethodArgumentNotValidException())
			.add(new HandleHttpMessageNotReadableException())
			;
			
	
	@Override
	public boolean canHandle(Exception value) {
		return container.canHandle(value);
	}
	
	@Override
	public ApiBadRequest process(Exception value) {
		return container.process(value).orElse(new ApiBadRequest(value.getMessage()));
	}

}
