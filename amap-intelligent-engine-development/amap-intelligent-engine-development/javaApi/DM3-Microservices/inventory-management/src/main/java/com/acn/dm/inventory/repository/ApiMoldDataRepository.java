package com.acn.dm.inventory.repository;

import com.acn.dm.inventory.domains.ApiMoldData;
import com.acn.dm.inventory.domains.pk.ApiMoldDataPK;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

@Repository
public interface ApiMoldDataRepository extends JpaRepository<ApiMoldData, ApiMoldDataPK>, JpaSpecificationExecutor<ApiMoldData> {

}
