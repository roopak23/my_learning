package com.acn.dm.common.utils;

import static org.junit.Assert.assertNotNull;

import java.util.HashSet;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

import lombok.extern.slf4j.Slf4j;

/**
 * @author Shivani Chaudhary
 *
 */
@Slf4j
public class ActionChainContainer<T,E> {

	private Set<ActionChain<T, E>> chain = new HashSet<>();
	
	public ActionChainContainer<T,E> add(ActionChain<T, E> action){
		assertNotNull("Invalid Action", action);
		if(this.chain.contains(action)) 
			log.warn("Action {} already registered", action.getClass());
		else
			this.chain.add(action);
		return this;
	}
	
	public boolean canHandle(T value) {
		return chain.parallelStream().filter(e -> {
			boolean can = e.canHandle(value);
			if(can)
				log.info("class {} can handle {}",e.getClass().getName(),value.getClass().getName());
			else
				log.info("class {} can't handle {}",e.getClass().getName(),value.getClass().getName());
			return can;
		}).findAny().isPresent();
	}
		
	public Optional<E> process(T value) {
		E res = null;
		Optional<ActionChain<T, E>> action = chain.parallelStream().filter(e -> e.canHandle(value)).findFirst();
		if(action.isPresent()) {
			log.info("Handle with class {} the value {}", action.get().getClass().getName(),value);
			res =action.get().process(value);
		}else {
			log.warn("No class in {} can handle {}", getRegistredClassList(), value);
		}
		return Optional.ofNullable(res);
	}
	
	private Set<String> getRegistredClassList() {
		// @formatter:off
		return chain
				.parallelStream()
				.map(Object::getClass)
				.map(Class::getName)
				.collect(Collectors.toSet())
			;
		// @formatter:on
	}
	
}
