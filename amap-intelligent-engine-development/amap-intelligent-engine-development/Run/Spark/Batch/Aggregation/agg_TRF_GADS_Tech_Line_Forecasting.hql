SET hive.auto.convert.join= FALSE;

CREATE TABLE TRF_GADS_Tech_Line_Forecasting_temp as 
SELECT 
	customer_id, 
	remote_id, 
	metric, 
	forecasted_quantity, 
	partition_date
	FROM (
		SELECT 
		customer_id, 
		adgroup_id as remote_id, 
		partition_date, 
		MAP('impressions', impressions, 'ctr', ctr, 'average_cpc', average_cpc, 'clicks', clicks, 'cost_micros', cost_micros) AS metric_forecasted_quantities 
		FROM stg_gads_future_campaign_performances where partition_date = {{ params.ENDDATE }}
		) t
		LATERAL VIEW EXPLODE(metric_forecasted_quantities) fv AS metric, forecasted_quantity;

INSERT OVERWRITE TABLE TRF_GADS_Tech_Line_Forecasting PARTITION (partition_date = {{ params.ENDDATE }})
SELECT 
	a.customer_id, 
	a.remote_id, 
	a.metric, 
	a.forecasted_quantity, 
	b.start_date, 
	b.end_date,
	b.unit_net_price, 
	c.adserver_id as system_id 
	FROM TRF_GADS_Tech_Line_Forecasting_temp a 
INNER JOIN trf_campaign b 
ON a.remote_id = b.remote_id 
AND a.partition_date = b.partition_date 
INNER JOIN stg_sa_ad_ops_system c 
ON b.system_id = c.adserver_id 
AND b.partition_date = c.partition_date 
WHERE a.partition_date = {{ params.ENDDATE }} and UPPER(TRIM(c.adserver_type)) = 'GADS';

DROP TABLE IF EXISTS TRF_GADS_Tech_Line_Forecasting_temp;