INSERT OVERWRITE TABLE TRF_Historical_Capacity partition(partition_date = {{ params.ENDDATE }})
Select
	a.`date`,
	c.adserver_id,
	c.adserver_adslot_id,
	a.adserver_adslot_name,
	c.adserver_target_remote_id,
	c.adserver_target_name,
	c.ratio * a.unifilled_impression AS unfilled_metric,
	a.metric
From TRF_adserver_InvHistorical a
INNER JOIN TRF_perf_gathering_metric b ON a.adserver_adslot_id = b.adserver_adslot_id
	AND a.adserver_id = b.adserver_id
INNER JOIN TRF_percentage_vs_all c ON c.adserver_adslot_id= b.adserver_adslot_id
	AND c.adserver_id= b.adserver_id
	AND c.adserver_target_remote_id = b.adserver_target_remote_id
WHERE a.partition_date= {{ params.ENDDATE }}
	AND b.partition_date= {{ params.ENDDATE }}
	AND UPPER(TRIM(a.metric)) = "IMPRESSION"
UNION
Select
	a.`date`,
	a.adserver_id,
	a.adserver_adslot_id,
	a.adserver_adslot_name,
	a.adserver_target_remote_id,
	a.adserver_target_name,
	b.metric_quantity - a.metric_quantity AS unfilled_metric,
	a.metric
From TRF_perf_gathering_metric a
INNER JOIN TRF_perf_gathering_metric b ON a.adserver_adslot_id= b.adserver_adslot_id
	AND a.adserver_target_remote_id = b.adserver_target_remote_id
	AND a.adserver_id= b.adserver_id
WHERE a.partition_date= {{ params.ENDDATE }}
	AND b.partition_date = {{ params.ENDDATE }}
	AND UPPER(TRIM(a.metric)) = "CLICK"
	AND UPPER(TRIM(b.metric)) = "IMPRESSION"