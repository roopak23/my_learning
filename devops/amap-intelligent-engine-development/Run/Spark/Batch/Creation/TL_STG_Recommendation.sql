CREATE TABLE IF NOT EXISTS `STG_TL_Recommendation` (
	`sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
	`remote_id` STRING,
	`recommendation_id` STRING,
	`recommendation_type` STRING,
	`recommendation_value` String,
	`customer_id` STRING
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_TL_Recommendation'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `STG_TL_Recommendation`;