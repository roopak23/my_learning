CREATE TABLE IF NOT EXISTS `TRF_TL_Recommendation` (
	`tech_line_id` STRING,
	`status` STRING,
	`remote_id` STRING,
	`recommendation_id` STRING,
	`recommendation_type` STRING,
	`recommendation_value` String,
	`customer_id` STRING
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_TL_Recommendation'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `TRF_TL_Recommendation`;