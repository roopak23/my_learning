CREATE TABLE IF NOT EXISTS `TL_Recommendation` (
	`tech_line_id` STRING,
	`status` STRING,
	`remote_id` STRING,
	`recommendation_id` STRING,
	`recommendation_type` STRING,
	`recommendation_value` String,
	`customer_id` STRING,
	`original_value` STRING,
	`recommendation_impact` DOUBLE
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TL_Recommendation'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `TL_Recommendation`;