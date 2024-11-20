package com.acn.dm.order.repository;

import com.acn.dm.order.domains.ApiOrderMessageQueue;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ApiOrderMessageQueueRepository extends JpaRepository<ApiOrderMessageQueue, Long>, JpaSpecificationExecutor<ApiOrderMessageQueue> {

    @Query(value = "SELECT market_order_details_status FROM api_order_message_queue " +
            "WHERE market_order_details_id = :marketOrderId " +
            "AND market_order_id = :moldId " +
            "ORDER BY id DESC " +
            "LIMIT 1 ", nativeQuery = true)
    Optional<String> findPreviousStatus(@Param("marketOrderId") String marketOrderId, @Param("moldId") String moldId);

}
