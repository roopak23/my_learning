SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_TO_Recommendation PARTITION (partition_date = {{ params.ENDDATE }})
SELECT DISTINCT b.tech_order_id
	,"NEW" AS status
	,a.remote_id
	,a.recommendation_id
	,a.recommendation_type
	,a.recommendation_value
	,a.customer_id
FROM stg_to_recommendation a
INNER JOIN stg_sa_tech_order B ON a.remote_id = b.order_remote_id
		AND a.partition_date = b.partition_date
WHERE a.partition_date = {{ params.ENDDATE }};