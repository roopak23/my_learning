SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE Industry_Audience PARTITION (partition_date = {{ params.ENDDATE }})
SELECT
	industry
	,audience_id 
	,audience_name 
	,audience_frequency
From TRF_Industry_Audience
WHERE audience_frequency >= 3
AND partition_date = {{ params.ENDDATE }};