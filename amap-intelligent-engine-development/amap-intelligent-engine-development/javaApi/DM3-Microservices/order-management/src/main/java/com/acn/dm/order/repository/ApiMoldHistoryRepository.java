package com.acn.dm.order.repository;

import com.acn.dm.order.domains.ApiMoldHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface ApiMoldHistoryRepository extends JpaRepository<ApiMoldHistory, String>, JpaSpecificationExecutor<ApiMoldHistory> {
}
