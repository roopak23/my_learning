CREATE TABLE IF NOT EXISTS `STG_SA_Creative` (
	`sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
	`creative_id` STRING,
	`advertiser_id` STRING,
	`system_id` STRING,
	`remote_id` String,
	`tech_line_id` String,
	`creative_size` STRING,
	`creative_ad_type` String,
	`creative_destination_url` String,
	`creative_call_to_action` String
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_Creative'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `STG_SA_Creative`;