package com.acn.dm.order.repository;

import com.acn.dm.order.domains.ApiInventoryCheck;
import com.acn.dm.order.domains.ApiInventoryCheckNativeDTO;
import com.acn.dm.order.projection.AdSlotChildrenProjection;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;


@Repository
public interface ApiInventoryCheckRepository extends JpaRepository<ApiInventoryCheck, Long>, JpaSpecificationExecutor<ApiInventoryCheck> {

    String query = "with recursive cte (adserver_id, adserver_adslot_id, adserver_adslot_parent_id) as (select adserver_id , adserver_adslot_id , adserver_adslot_parent_id from api_adslot_hierarchy " +
            "where adserver_adslot_parent_id in(:param_adslot_parent_id) AND adserver_id=:param_adserver_id union all select aah.adserver_id , aah.adserver_adslot_id , aah.adserver_adslot_parent_id from api_adslot_hierarchy " +
            "aah inner join cte on aah.adserver_adslot_parent_id = cte.adserver_adslot_id and aah.adserver_id=cte.adserver_id) select * from cte;";

    // function enabling conducting recursive query.
    // Binding parameters protects from SQL injections attack
    @Query(value = query, nativeQuery = true)
    List<AdSlotChildrenProjection> findAllChildAdSlots(@Param("param_adslot_parent_id") String param_adslot_parent_id, @Param("param_adserver_id") String param_adserver_id);

    @Query(value = inventorySelect, nativeQuery = true)
    List<ApiInventoryCheckNativeDTO> inventorySelect(@Param("metric") String metric
            , @Param("adSlotIds") List<String> adSlotId
            , @Param("labels") List<String> labels
            , @Param("marketOrderId") String marketOrderId
            , @Param("adServerIds") List<String> adServerId
            , @Param("cities") List<String> city
            , @Param("excludedCity") List<String> excludedCity
            , @Param("states") List<String> states
            , @Param("excludedState") List<String> excludedState
            , @Param("events") List<String> events
            , @Param("videoPositions") List<String> videoPositions
            , @Param("podPositions") List<String> podPositions
            , @Param("audiences") List<String> audiences
            , @Param("startDate") LocalDate startDate
            , @Param("endDate") LocalDate endDate
            , @Param("cap") List<String> cap);


    @Query(value = inventorySelectByKey, nativeQuery = true)
    List<ApiInventoryCheck> inventorySelectByKey(@Param("metric") String metric
            , @Param("adSlotIds") Set<String> adSlotId
            , @Param("adServerIds") Set<String> adServerId
            , @Param("cities") Set<String> city
            , @Param("states") Set<String> states
            , @Param("events") Set<String> events
            , @Param("videoPositions") Set<String> videoPositions
            , @Param("podPositions") Set<String> podPositions
            , @Param("startDate") LocalDate startDate
            , @Param("endDate") LocalDate endDate);

    String inventorySelect = "SELECT " +
            " ai.`date` AS date, ai.state, ai.city, ai.event, booked, reserved, ai.future_capacity AS futureCapacity, ai.adserver_id AS adServerId, metric" +
            ", ai.adserver_adslot_id as adServerAdslotId, ai.pod_position AS podPosition, ai.video_position AS videoPosition, clash.clash AS clash, ai.version  " +
            ", ai.percentage_of_overwriting AS percentageOfOverwriting, ai.overwriting, COALESCE(ai.overwritten_impressions, 0) AS overwrittenImpressions, COALESCE(cap.factor, 1) AS factor" +
            ", ai.overwriting_reason AS overwritingReason, ai.use_overwrite AS useOverwrite,  COALESCE(saa.avg_percent / 100, 1) AS avgPercent, ai.audience_name AS audienceName" +
            ", ai.id as id, ai.overwritten_expiry_date as overwrittenExpiryDate, ai.updated_by as updatedBy, ai.missing_forecast as missingForecast " +
            "FROM api_inventorycheck ai " +
            "LEFT JOIN (SELECT AVG(aaa.`% audience`) AS avg_percent " +
            ",aaa.dimension state " +
            "FROM STG_Adserver_Audiencefactoring aaa " +
            "WHERE aaa.dimension_level = 'STATE' " +
            "AND aaa.audience_name IN (:audiences) " +
            "GROUP BY dimension) saa " +
            "ON ai.state = saa.state " +
            "LEFT JOIN (SELECT COALESCE(EXP(SUM(LOG(afcf.factor))), 0) AS factor " +
            ", afcf.adserver_adslot_id " +
            "FROM api_frequency_cap_factor afcf " +
            "WHERE CONCAT(UPPER(afcf.time_unit), '-', afcf.max_impressions, '-', afcf.num_time_units) IN (:cap) " +
            "AND afcf.adserver_adslot_id IN (:adSlotIds) " +
            "GROUP BY afcf.adserver_adslot_id) cap " +
            "ON ai.adserver_adslot_id = cap.adserver_adslot_id " +
            "LEFT JOIN (SELECT adserver_adslot_id " +
            ", video_position " +
            ", 'Y' AS clash " +
            ", arh.`date` " +
            "FROM api_reserved_history arh " +
            "JOIN api_mold_attrib ama " +
            "ON arh.market_order_line_details_id = ama.market_order_line_details_id " +
            "WHERE arh.`date` BETWEEN :startDate AND :endDate " +
            "AND ama.attrib_type = 'LABEL' " +
            "AND arh.status <> 'CANCELLED' " +
            "AND arh.status <> 'RETRACTED' " +
            "AND UPPER(arh.calc_type) <> 'CLASH' " +
            "AND arh.adserver_adslot_id IN (:adSlotIds) " +
            "AND ama.attrib_value IN (:labels) " +
            "AND (COALESCE(:videoPositions) IS NULL OR arh.video_position IN (:videoPositions)) " +
            "AND arh.market_order_id <> :marketOrderId " +
            "AND 1 = 0 " +
            "GROUP BY adserver_adslot_id, video_position, arh.`date`) clash " +
            "ON (ai.adserver_adslot_id = clash.adserver_adslot_id " +
            "AND ai.video_position = clash.video_position " +
            "AND ai.`date` = clash.`date`) " +
            "WHERE ai.adserver_adslot_id IN (:adSlotIds) " +
            "AND ai.adserver_id IN (:adServerIds) " +
            "AND ai.metric = :metric " +
            "AND (((COALESCE(:states) IS NULL AND COALESCE(:cities) IS NULL) " +
            "OR ((COALESCE(:states) IS NOT NULL AND ai.state IN (:states)) " +
            "OR (COALESCE(:cities) IS NOT NULL AND ai.city IN (:cities))))) " +
            "AND (COALESCE(:events) IS NULL OR ai.event IN (:events)) " +
            "AND (COALESCE(:podPositions) IS NULL OR ai.pod_position IN (:podPositions)) " +
            "AND (COALESCE(:videoPositions) IS NULL OR ai.video_position IN (:videoPositions)) " +
            "AND (COALESCE(:excludedCity) IS NULL OR ai.city NOT IN (:excludedCity)) " +
            "AND (COALESCE(:excludedState) IS NULL OR ai.state NOT IN (:excludedState)) " +
            "AND (ai.missing_forecast = 'N' or ai.use_overwrite = 'Y') " +
            "AND ai.`date` BETWEEN :startDate AND :endDate ;";

    String inventorySelectByKey = "SELECT " +
            " ai.`date` , ai.state, ai.city, ai.event, ai.booked, ai.reserved, ai.future_capacity , ai.adserver_id , ai.metric" +
            ", ai.adserver_adslot_id , ai.pod_position , ai.video_position, ai.id, ai.missing_segment " +
            ", ai.percentage_of_overwriting , ai.overwriting, ai.overwritten_impressions  " +
            ", ai.overwriting_reason , ai.use_overwrite , ai.audience_name , ai.version " +
            ", ai.overwritten_expiry_date , ai.updated_by , ai.missing_forecast , ai.adserver_adslot_name  " +
            "FROM api_inventorycheck ai " +
            "WHERE ai.adserver_adslot_id IN (:adSlotIds) " +
            "AND ai.`date` BETWEEN :startDate AND :endDate " +
            "AND ai.metric = :metric " +
            "AND (((COALESCE(:states) IS NULL AND COALESCE(:cities) IS NULL) " +
            "OR ((COALESCE(:states) IS NOT NULL AND ai.state IN (:states)) " +
            "OR (COALESCE(:cities) IS NOT NULL AND ai.city IN (:cities))))) " +
            "AND (COALESCE(:events) IS NULL OR ai.event IN (:events)) " +
            "AND (COALESCE(:podPositions) IS NULL OR ai.pod_position IN (:podPositions)) " +
            "AND (COALESCE(:videoPositions) IS NULL OR ai.video_position IN (:videoPositions)) " +
            "AND ai.adserver_id IN (:adServerIds); ";
}
