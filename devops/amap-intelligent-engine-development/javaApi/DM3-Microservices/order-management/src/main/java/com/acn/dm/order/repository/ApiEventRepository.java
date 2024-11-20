package com.acn.dm.order.repository;

import com.acn.dm.order.domains.ApiEvent;
import java.util.Collection;
import java.util.List;
import java.util.Set;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ApiEventRepository extends JpaRepository<ApiEvent, Long>, JpaSpecificationExecutor<ApiEvent> {

    @Query(value = "SELECT id, event_key, event_value FROM api_master_events WHERE event_key IN (:eventKey) AND event_value IN (:eventVal)", nativeQuery = true)
    List<ApiEvent> findEvents(@Param("eventKey") Set<String> keys, @Param("eventVal") Collection<String> values);
}
