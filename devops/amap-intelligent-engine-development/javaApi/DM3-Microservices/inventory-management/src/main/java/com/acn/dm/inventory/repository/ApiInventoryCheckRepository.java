package com.acn.dm.inventory.repository;

import com.acn.dm.inventory.domains.ApiInventoryCheck;
import com.acn.dm.inventory.domains.pk.ApiInventoryCheckPK;
import com.acn.dm.inventory.projection.AdSlotChildrenProjection;
import com.acn.dm.inventory.projection.CheckProjectionDTO;
import com.acn.dm.inventory.projection.InquirityProjectionDTO;
import java.time.LocalDate;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface ApiInventoryCheckRepository extends JpaRepository<ApiInventoryCheck, Long>, JpaSpecificationExecutor<ApiInventoryCheck> {

    // function enabling conducting recursive query.
    @Query(value = query, nativeQuery = true)
    List<AdSlotChildrenProjection> findAllChildAdSlots(@Param("param_adslot_parent_id") String param_adslot_parent_id, @Param("param_adserver_id") String param_adserver_id);

    @Query(value = inventoryCheckQuery, nativeQuery = true)
    List<CheckProjectionDTO> getInventoryCheckQuery(@Param("metric") String metric
            , @Param("adSlotIds") List<String> adSlotId
            , @Param("excludedAdSlotIds") List<String> inCorrectSlotId
            , @Param("labels") List<String> labels
            , @Param("moldId") String moldId
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

    @Query(value = inventoryInqiurityQuery, nativeQuery = true)
    List<InquirityProjectionDTO> getInventoryInqiurityQuery(@Param("metric") List<String> metric
            , @Param("adSlotIds") List<String> adSlotId
            , @Param("excludedAdSlotIds") List<String> inCorrectSlotId
            , @Param("adServerIds") List<String> adServerId
            , @Param("cities") List<String> city
            , @Param("states") List<String> states
            , @Param("events") List<String> events
            , @Param("audiences") List<String> audiences
            , @Param("startDate") LocalDate startDate
            , @Param("endDate") LocalDate endDate);

    // recursive query defined, possible to move to this to some constants class
    String query = "with recursive cte (adserver_id, adserver_adslot_id, adserver_adslot_parent_id) as (select adserver_id , adserver_adslot_id , adserver_adslot_parent_id from api_adslot_hierarchy " +
            "where adserver_adslot_parent_id in(:param_adslot_parent_id) AND adserver_id=:param_adserver_id union all select aah.adserver_id , aah.adserver_adslot_id , aah.adserver_adslot_parent_id from api_adslot_hierarchy " +
            "aah inner join cte on aah.adserver_adslot_parent_id = cte.adserver_adslot_id and aah.adserver_id=cte.adserver_id) select * from cte;";

    String inventoryInqiurityQuery = "SELECT " +
            " SUM((future_capacity - (booked + reserved)) * COALESCE(avg_percent / 100, 1)) AS available " +
            ",metric AS metric " +
            ",SUM(future_capacity) AS capacity " +
            ",SUM(reserved) AS reserved " +
            ",SUM(booked) AS booked " +
            "FROM (SELECT metric, avg_percent, booked, reserved,   " +
            "CASE " +
            "WHEN use_overwrite = 'Y' THEN " +
            "COALESCE(overwritten_impressions, 0) " +
            "ELSE " +
            "future_capacity " +
            "END future_capacity " +
            "FROM api_inventorycheck ai " +
            "LEFT JOIN (SELECT AVG(aaa.`% audience`) AS avg_percent " +
            ",aaa.dimension state " +
            "FROM STG_Adserver_Audiencefactoring aaa " +
            "WHERE aaa.dimension_level = 'STATE' " +
            "AND aaa.audience_name IN (:audiences) " +
            "GROUP BY dimension) saa " +
            "ON ai.state = saa.state " +
            "WHERE (COALESCE(:adSlotIds) IS NULL OR ai.adserver_adslot_id IN (:adSlotIds)) " +
            "AND ai.adserver_id IN (:adServerIds) " +
            "AND ai.metric IN (:metric) " +
            "AND (((COALESCE(:states) IS NULL AND COALESCE(:cities) IS NULL) " +
            "OR ((COALESCE(:states) IS NOT NULL AND ai.state IN (:states)) " +
            "OR (COALESCE(:cities) IS NOT NULL AND ai.city IN (:cities))))) " +
            "AND (COALESCE(:events) IS NULL OR ai.event IN (:events)) " +
            "AND (COALESCE(:excludedAdSlotIds) IS NULL OR ai.adserver_adslot_id NOT IN (:excludedAdSlotIds)) " +
            "AND (ai.missing_forecast = 'N' or ai.use_overwrite = 'Y') " +
            "AND ai.`date` BETWEEN :startDate AND :endDate) result " +
            "GROUP BY metric;";

    String inventoryCheckQuery = "SELECT " +
            " SUM((future_capacity - (booked + reserved)) * COALESCE(avg_percent / 100, 1) * COALESCE(factor, 1) ) AS available " +
            ",metric AS metric " +
            ",SUM(future_capacity) AS capacity " +
            ",SUM(reserved) AS reserved " +
            ",SUM(booked) AS booked " +
            ",MAX(clash) AS clash " +
            "FROM (SELECT metric, clash.clash, avg_percent, factor " +
            ",CASE " +
            "WHEN clash = 'Y' THEN " +
            "0 " +
            "ELSE " +
            "reserved " +
            "END reserved " +
            ",CASE " +
            "WHEN clash = 'Y' THEN " +
            "0 " +
            "ELSE " +
            "booked " +
            "END booked " +
            ",CASE " +
            "WHEN clash = 'Y' THEN " +
            "0 " +
            "ELSE " +
            "CASE " +
            "WHEN use_overwrite = 'Y' THEN " +
            "COALESCE(overwritten_impressions, 0) " +
            "ELSE " +
            "future_capacity " +
            "END " +
            "END future_capacity " +
            "FROM api_inventorycheck ai " +
            "LEFT JOIN (SELECT AVG(aaa.`% audience`) AS avg_percent " +
            ",aaa.dimension state " +
            "FROM STG_Adserver_Audiencefactoring aaa " +
            "WHERE aaa.dimension_level = 'STATE' " +
            "AND aaa.audience_name IN (:audiences) " +
            "GROUP BY dimension) saa " +
            "ON ai.state = saa.state " +
            "LEFT JOIN (SELECT COALESCE(EXP(SUM(LOG(afcf.factor))),0) AS factor " +
            ", afcf.adserver_adslot_id " +
            "FROM api_frequency_cap_factor afcf " +
            "WHERE CONCAT(UPPER(afcf.time_unit), '-', afcf.max_impressions, '-', afcf.num_time_units) IN (:cap) " +
            "AND afcf.adserver_adslot_id IN (:adSlotIds) " +
            "GROUP BY afcf.adserver_adslot_id) cap " +
            "ON ai.adserver_adslot_id = cap.adserver_adslot_id " +
            "LEFT JOIN (SELECT adserver_adslot_id " +
            ",video_position " +
            ",'Y' AS clash " +
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
            "AND (arh.market_order_id <> (select min(b.market_order_id) from api_mold_attrib b where b.market_order_line_details_id = :moldId )) " +
            "AND 1 = 0 " +
            "GROUP BY adserver_adslot_id, video_position, arh.`date`) clash " +
            "ON (ai.adserver_adslot_id = clash.adserver_adslot_id " +
            "AND ai.video_position = clash.video_position " +
            "AND ai.`date` = clash.`date`) " +
            "WHERE (COALESCE(:adSlotIds) IS NULL OR ai.adserver_adslot_id IN (:adSlotIds)) " +
            "AND ai.adserver_id IN (:adServerIds) " +
            "AND ai.metric = :metric " +
            "AND (((COALESCE(:states) IS NULL AND COALESCE(:cities) IS NULL) " +
            "OR ((COALESCE(:states) IS NOT NULL AND ai.state IN (:states)) " +
            "OR (COALESCE(:cities) IS NOT NULL AND ai.city IN (:cities))))) " +
            "AND (COALESCE(:events) IS NULL OR ai.event IN (:events)) " +
            "AND (COALESCE(:podPositions) IS NULL OR ai.pod_position IN (:podPositions)) " +
            "AND (COALESCE(:videoPositions) IS NULL OR ai.video_position IN (:videoPositions)) " +
            "AND (COALESCE(:excludedAdSlotIds) IS NULL OR ai.adserver_adslot_id NOT IN (:excludedAdSlotIds)) " +
            "AND (COALESCE(:excludedCity) IS NULL OR ai.city NOT IN (:excludedCity)) " +
            "AND (COALESCE(:excludedState) IS NULL OR ai.state NOT IN (:excludedState)) " +
            "AND (ai.missing_forecast = 'N' or ai.use_overwrite = 'Y') " +
            "AND ai.`date` BETWEEN :startDate AND :endDate) result " +
            "GROUP BY metric;";
}
