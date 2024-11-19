SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TO_Recommendation PARTITION (partition_date = {{ params.ENDDATE }})
SELECT a.tech_order_id
	,a.status
	,a.remote_id
	,a.recommendation_id
	,a.recommendation_type
	,a.recommendation_value
	,a.customer_id
FROM trf_to_recommendation a
WHERE a.partition_date = {{ params.ENDDATE }}