package com.acn.dm.common.utils;

/**
 * 
 * Simple Action Chain
 * 
 * @author Shivani Chaudhary
 *
 */
public interface ActionChain<T,E> {
	public E process(T value);
	public boolean canHandle(T value);
}
