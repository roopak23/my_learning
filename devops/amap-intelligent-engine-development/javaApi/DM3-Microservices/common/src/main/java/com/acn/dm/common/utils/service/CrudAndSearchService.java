package com.acn.dm.common.utils.service;

import java.io.Serializable;
import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;

/**
 * @author Shivani Chaudhary
 *
 */
public interface CrudAndSearchService<ID, T extends Serializable> extends CrudService<ID, T> {

	
	public List<T> find(Specification<T> filter);
	public Page<T> find(Specification<T> filter,Pageable page);


}
