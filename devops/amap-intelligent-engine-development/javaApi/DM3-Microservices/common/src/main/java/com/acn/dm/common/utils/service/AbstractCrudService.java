package com.acn.dm.common.utils.service;

import java.io.Serializable;
import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;



/**
 * @author Shivani Chaudhary
 *
 */
public abstract class AbstractCrudService<ID, T extends Serializable, E extends JpaRepository<T, ID>> implements CrudService<ID, T> {

	protected final E repo;

	public AbstractCrudService(E repo) {
		this.repo = repo;
	}

	public List<T> find() {
		return repo.findAll();
	}

	public Optional<T> findById(ID id){
		return repo.findById(id);
	}

	@Transactional
	public void deleteAll(){
		repo.deleteAll();
	}
	
	@Transactional
	public void delete(T item) {
		repo.delete(item);
	}
	
	@Transactional
	public void delete(ID id) {
		repo.deleteById(id);
	}
	
	public Page<T> find(Pageable page){
		return repo.findAll(page);
	}
	

}
