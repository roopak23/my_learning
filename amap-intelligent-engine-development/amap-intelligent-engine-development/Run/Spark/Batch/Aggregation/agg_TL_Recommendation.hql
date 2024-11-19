SET hive.auto.convert.join= FALSE;

ALTER TABLE TL_Recommendation DROP IF EXISTS PARTITION (partition_date = {{ params.ENDDATE }}) PURGE;
INSERT INTO TABLE TL_Recommendation PARTITION (partition_date = {{ params.ENDDATE }})
SELECT c.tech_line_id
	,'NEW' as status
	,a.remote_id
	,a.recommendation_id
	,a.recommendation_type
	,a.recommendation_value
	,a.customer_id
	,NULL AS original_value
	,NULL AS recommendation_impact
FROM trf_tl_recommendation a left join trf_fact_input b on a.tech_line_id = b.tech_line_id and a.partition_date = b.partition_date 
INNER JOIN stg_sa_tech_line_details c on a.tech_line_id = c.tech_line_id and a.partition_date = c.partition_date 
WHERE a.partition_date = {{ params.ENDDATE }} and b.flag_optimisation = 1 
UNION ALL 
SELECT 
	a.tech_line_id
	,'NEW' as status
	,a.remote_id
	,a.model_id AS recommendation_id
	,a.optimization_type AS recommendation_type
	,concat('{ "commercial_id": "', a.commercial_id, '" }') AS recommendation_value
	,NULL AS customer_id
	,a.original_value
	,((a.predicted_units - a.original_predicted_units)/a.original_predicted_units) * 100 as recommendation_impact
FROM 
trf_gam_recommendation a 
WHERE a.partition_date = {{ params.ENDDATE }} and a.predicted_units > a.original_predicted_units
UNION ALL
SELECT
    a.tech_line_id
    ,'NEW' as status
    ,b.remote_id
    ,a.model_id AS recommendation_id
    ,a.optimization_type AS recommendation_type
    ,concat('{ "commercial_id": "', a.commercial_id, '" }') AS recommendation_value
    ,NULL AS customer_id
    ,a.original_value
    ,NULL as recommendation_impact
FROM
trf_onnet_model_output a
INNER JOIN stg_sa_tech_line_details b
ON b.tech_line_id = a.tech_line_id AND a.partition_date = b.partition_date
JOIN stg_sa_ad_ops_system c
ON b.system_id = c.adserver_id AND b.partition_date = c.partition_date
WHERE a.partition_date = {{ params.ENDDATE }} and b.partition_date = {{ params.ENDDATE }} and c.partition_date = {{ params.ENDDATE }}
AND c.adserver_type = 'DV360'