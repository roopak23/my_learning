SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_Industry_Audience PARTITION (partition_date = {{ params.ENDDATE }})
SELECT 
	a.market_order_id
	,a.agency
	,a.industry
	,a.stdt
	,a.endt
	,a.days_elapsed
	,a.commercial_audience
	,a.commercial_audience_name
	,a.audience_duration
	,CASE 
		WHEN a.audience_duration = 'OK' THEN COUNT(a.agency) OVER (PARTITION BY a.industry,a.commercial_audience_name)
		WHEN a.audience_duration != 'OK' THEN 0
		END AS audience_frequency
	From ( SELECT 
		market_order_id
		,agency
		,industry
		,to_date(from_unixtime(start_date DIV 1000)) as stdt
		,to_date(from_unixtime(end_date DIV 1000)) as endt
		,DATEDIFF(CURRENT_DATE(),to_date(from_unixtime(start_date DIV 1000))) AS days_elapsed 
		,commercial_audience
		,commercial_audience_name
		,IF(DATEDIFF(CURRENT_DATE(),to_date(from_unixtime(start_date DIV 1000))) <180,'OK','KO') as audience_duration
	FROM stg_sa_market_order
	WHERE partition_date = {{ params.ENDDATE }} AND agency IS NOT NULL) A;