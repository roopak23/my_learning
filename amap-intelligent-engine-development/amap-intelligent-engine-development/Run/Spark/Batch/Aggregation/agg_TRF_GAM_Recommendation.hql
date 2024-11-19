SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_GAM_Recommendation PARTITION (partition_date = {{ params.ENDDATE }})
SELECT DISTINCT a.remote_id
	,a.order_remote_id
	,a.unit_type
	,a.predicted_units
	,a.quantity_delivered
	,a.matched_units
	,b.tech_line_id
	,b.tech_order_id
	,b.model_id
	,b.optimization_type
	,b.technical_id
	,b.commercial_id
	,b.original_value
	,b.original_predicted_units 
FROM TRF_Adserver_Forecast_Output a 
INNER JOIN TRF_Onnet_Model_Output b 
ON a.model_id = b.model_id and a.partition_date = b.partition_date 
WHERE a.partition_date = {{ params.ENDDATE }}