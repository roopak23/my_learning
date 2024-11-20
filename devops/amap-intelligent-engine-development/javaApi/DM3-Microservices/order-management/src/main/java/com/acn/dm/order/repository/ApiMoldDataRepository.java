package com.acn.dm.order.repository;


import com.acn.dm.order.domains.ApiMoldData;
import com.acn.dm.order.domains.pk.ApiMoldDataPK;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

@Repository
public interface ApiMoldDataRepository extends JpaRepository<ApiMoldData, ApiMoldDataPK>, JpaSpecificationExecutor<ApiMoldData> {

    @Query(value = "DELETE FROM api_mold_attrib WHERE market_order_line_details_id = ?1", nativeQuery = true)
    String deleteByIdMoldId(String moldId);

}
