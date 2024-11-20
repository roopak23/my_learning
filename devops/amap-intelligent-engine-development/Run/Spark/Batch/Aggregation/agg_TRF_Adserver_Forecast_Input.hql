SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_Adserver_Forecast_Input PARTITION (partition_date = {{ params.ENDDATE }})
SELECT a.tech_line_id
	,b.remote_id
	,a.tech_order_id
	,d.order_remote_id
	,a.model_id
	,b.start_date
	,b.end_date
	,CASE WHEN UPPER(TRIM(a.optimization_type)) = 'PRODUCT' THEN a.technical_id ELSE 'NULL' END as product_suggestion
	,b.adserver_target_type
	,CASE WHEN UPPER(TRIM(a.optimization_type)) = 'AUDIENCE' THEN a.technical_id ELSE 'NULL' END as audience_suggestion
	,CASE WHEN UPPER(TRIM(a.optimization_type)) = 'PRIORITY' THEN a.commercial_id ELSE 'NULL' END as priority_suggestion
	,b.frequency_capping
	,CASE WHEN UPPER(TRIM(a.optimization_type)) = 'FREQUENCY' THEN a.commercial_id ELSE 'NULL' END as frequency_suggestion
	,b.unit_price as cost_per_unit
	,a.unit_type as metric
	,b.objective as campaign_objective
	,e.creative_size 
FROM TRF_Onnet_Model_Output a 
INNER JOIN TRF_Campaign b 
ON a.tech_line_id = b.tech_line_id and a.partition_date = b.partition_date 
INNER JOIN STG_SA_Tech_Line_Details c 
ON c.tech_line_id = b.tech_line_id and c.partition_date = b.partition_date 
INNER JOIN STG_SA_Tech_Order d 
ON d.tech_order_id = c.tech_order_id and d.partition_date = c.partition_date 
INNER JOIN STG_SA_Creative e 
ON e.tech_line_id = c.tech_line_id and e.partition_date = c.partition_date
JOIN stg_sa_ad_ops_system f
ON c.system_id = f.adserver_id and c.partition_date= f.partition_date
WHERE a.partition_date = {{ params.ENDDATE }} AND f.adserver_type = 'GAM'