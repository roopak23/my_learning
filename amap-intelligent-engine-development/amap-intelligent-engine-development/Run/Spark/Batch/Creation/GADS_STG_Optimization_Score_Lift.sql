CREATE TABLE IF NOT EXISTS `STG_GADS_Optimization_Score_lift` (
	`sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
	`tech_order_remote_id` STRING,
	`tech_order_remote_name` STRING,
	`status` STRING,
	`start_date` Date,
	`end_date` Date,
	`type` STRING,
	`actual_pacing_uplift` DOUBLE,
	`recommendation_type` STRING
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_GADS_Optimization_Score_lift'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `STG_GADS_Optimization_Score_lift`;