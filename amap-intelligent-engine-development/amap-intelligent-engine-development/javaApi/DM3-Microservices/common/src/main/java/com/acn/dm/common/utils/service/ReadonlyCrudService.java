package com.acn.dm.common.utils.service;

import java.io.Serializable;
import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

/**
 * @author Shivani Chaudhary
 *
 */
public interface ReadonlyCrudService<ID, T extends Serializable> {

	public List<T> find();

	public Optional<T> findById(ID id);

	public Page<T> find(Pageable page);

}
