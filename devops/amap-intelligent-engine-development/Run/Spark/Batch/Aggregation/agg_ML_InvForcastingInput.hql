INSERT OVERWRITE TABLE ml_invforecastinginput PARTITION (partition_date = {{ params.ENDDATE }})
SELECT DISTINCT
    a.`date`,
    b.adserver_id,
    a.adserver_adslot_id,
    '' AS adserver_target_remote_id,
    '' AS adserver_target_name,
    '' AS adserver_target_type,
    COALESCE(ROUND(A.impressions + (b.unmatched_ad_requests),0),ROUND(A.impressions,0)) AS historical_capacity,
    COALESCE(b.metric,'IMPRESSIONS') AS metric,
    b.adserver_adslot_name
FROM (Select 
        adserver_adslot_id, 
        `date`, 
        sum(impressions) as impressions,
        partition_date
        from trf_dtf_additional_dimensions 
        Where partition_date = {{ params.ENDDATE }} Group By adserver_adslot_id, `date`, partition_date)a
LEFT JOIN TRF_Adserver_InvHistorical B
    ON a.adserver_adslot_id = b.adserver_adslot_id
    AND a.`date` = b.`date`
WHERE a.partition_date = {{ params.ENDDATE }}
    AND b.partition_date = {{ params.ENDDATE }} ;
	
	
--INSERT OVERWRITE TABLE ml_invforecastinginput PARTITION (partition_date = {{ params.ENDDATE }})
--SELECT DISTINCT
--	a.`date`,
--	a.adserver_id,
--	a.adserver_adslot_id,
--	c.adserver_target_remote_id,
--	c.adserver_target_name,
--	c.adserver_target_type,
--	round(b.metric_quantity + a.unfilled_metric, 0) AS historical_capacity,
--	a.metric AS metric
--FROM TRF_Historical_capacity AS a
--INNER JOIN trf_perf_gathering_metric b ON a.adserver_adslot_id = b.adserver_adslot_id
--	AND a.adserver_id = b.adserver_id
--	AND a.`date` = b.`date`
--	AND a.metric = b.metric
--	AND a.adserver_target_remote_id = b.adserver_target_remote_id
--INNER JOIN TRF_AdUnitSegmentUsage c ON b.adserver_adslot_id = c.adserver_adunit_id
--    AND b.adserver_id = c.adserver_id
--	AND b.adserver_target_remote_id = c.adserver_target_remote_id
--INNER JOIN STG_NC_anagraphic d ON a.adserver_target_remote_id = d.dfp_id
--	AND b.adserver_target_remote_id = d.dfp_id
--	AND c.adserver_target_remote_id = d.dfp_id
--WHERE a.partition_date = {{ params.ENDDATE }}
--	AND b.partition_date = {{ params.ENDDATE }}
--	AND c.partition_date = {{ params.ENDDATE }}
--	AND d.partition_date = {{ params.ENDDATE }};
