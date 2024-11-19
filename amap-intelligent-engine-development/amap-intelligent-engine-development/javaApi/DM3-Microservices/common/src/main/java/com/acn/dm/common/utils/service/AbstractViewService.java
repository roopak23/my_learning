package com.acn.dm.common.utils.service;

import java.io.Serializable;
import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;



/**
 * @author Shivani Chaudhary
 *
 */
public abstract class AbstractViewService<ID, T extends Serializable, E extends JpaRepository<T, ID>> implements ReadonlyCrudService<ID, T>{

	protected final E repo;

	public AbstractViewService(E repo) {
		this.repo = repo;
	}

	public List<T> find() {
		return repo.findAll();
	}

	public Optional<T> findById(ID id){
		return repo.findById(id);
	}
		
	public Page<T> find(Pageable page){
		return repo.findAll(page);
	}
	

}
