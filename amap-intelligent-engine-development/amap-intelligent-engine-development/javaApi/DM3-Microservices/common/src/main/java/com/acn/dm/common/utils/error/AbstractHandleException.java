package com.acn.dm.common.utils.error;

import com.acn.dm.common.utils.ActionChain;
import jakarta.annotation.PostConstruct;
import java.util.Optional;


import org.apache.commons.lang.exception.ExceptionUtils;


import lombok.extern.slf4j.Slf4j;

/**
 * @author Alberto Riminucci
 *
 */
@Slf4j
public abstract class AbstractHandleException<E,T> implements ActionChain<Exception,T> {

	private final Class<E> clazz;
	
	public abstract T doHandle(E ex, Exception parent);
	
	public AbstractHandleException(Class<E> clazz) {
		super();
		this.clazz = clazz;
	}

	@Override
	public boolean canHandle(Exception value) {
		return getException(value).isPresent();
	}
	
	@Override
	public T process(Exception value) {
		Optional<E> ex = getException(value);
		if (ex.isPresent()) {
			return doHandle(ex.get(),value);
		}
		return null;
	}

	protected Optional<E> getException(Exception ex) {
		return ExceptionUtils.getThrowableList(ex).stream().filter(clazz::isInstance).map(clazz::cast).findAny();
	}
	
	@PostConstruct
	public void logInfo() {
		log.info("Register Exception Handler for {}", clazz.getName());
	}
	
}
