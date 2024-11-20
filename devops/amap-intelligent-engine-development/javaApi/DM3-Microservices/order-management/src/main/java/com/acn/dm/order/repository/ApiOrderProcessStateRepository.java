package com.acn.dm.order.repository;

import com.acn.dm.order.domains.ApiOrderProcessState;
import com.acn.dm.order.domains.pk.ApiOrderProcessStatePK;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface ApiOrderProcessStateRepository extends JpaRepository<ApiOrderProcessState, ApiOrderProcessStatePK>, JpaSpecificationExecutor<ApiOrderProcessState> {
}
