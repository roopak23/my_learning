INSERT OVERWRITE TABLE TRF_perf_gathering_metric partition(partition_date = {{ params.ENDDATE }})
Select distinct
	a.`date`,
	a.adserver_id,
    a.adserver_adslot_id,
    a.adserver_adslot_name,
    a.adserver_target_remote_id,
    a.adserver_target_name,
    a.metric_quantity,
	split(a.metric,'_')[1],
    a.adserver_target_type
From(
	select distinct
		`date`,
		`adserver_adslot_id`,
		`adserver_adslot_name`,
		`adserver_target_remote_id`,
		`adserver_target_name`,
		`metric_quantity`,
		`metric`,
		`adserver_id`,
		`adserver_target_type`,
		`partition_date`
	from stg_adserver_performancegathering lateral view explode(array(Impressions,Clicks)) PerformanceGathering as metric_quantity
		lateral view explode(array(concat(Impressions,'_',"IMPRESSION"),concat(Clicks,'_',"CLICK"))) PerformanceGathering as metric) A 
	WHERE metric_quantity=split(metric,'_')[0]
		AND A.partition_date = {{ params.ENDDATE }};