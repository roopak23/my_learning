package com.acn.dm.inventory.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import com.acn.dm.inventory.domains.StgSaAdOpsSystem;

@Repository
public interface StgSaAdOpsSystemRepository  extends JpaRepository<StgSaAdOpsSystem, String>, JpaSpecificationExecutor<StgSaAdOpsSystem> {

}

