package com.acn.dm.common.utils.service;

import java.io.Serializable;

/**
 * @author Shivani Chaudhary
 *
 */
public interface CrudService<ID, T extends Serializable> extends ReadonlyCrudService<ID, T> {

	public void deleteAll();

	public void delete(T item);

	public void delete(ID id);


}
