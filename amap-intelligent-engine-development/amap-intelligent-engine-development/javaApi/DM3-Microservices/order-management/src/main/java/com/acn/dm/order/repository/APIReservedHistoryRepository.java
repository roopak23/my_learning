package com.acn.dm.order.repository;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import com.acn.dm.order.domains.ApiReservedHistory;
import com.acn.dm.order.domains.pk.APIReservedHistoryPK;

/**
 * @author Shivani Chaudhary
 */
@Repository
public interface APIReservedHistoryRepository extends JpaRepository<ApiReservedHistory, APIReservedHistoryPK>, JpaSpecificationExecutor<ApiReservedHistory> {

    @Query(value = "Select a FROM ApiReservedHistory a WHERE a.id.moldId = ?1")
    List<ApiReservedHistory> findByMoldId(String moldId);
}
