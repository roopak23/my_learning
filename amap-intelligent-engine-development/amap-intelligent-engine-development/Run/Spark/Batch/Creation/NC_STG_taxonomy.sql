CREATE TABLE IF NOT EXISTS `STG_NC_taxonomy` (
	`sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
	`taxonomy_segment_name` STRING,
	`taxonomy_segment_type` STRING,
	`platform` STRING,
	`platform_segment_unique_id` STRING,
	`platform_segment_name` STRING,
	`news_connect_id` STRING
)
PARTITIONED BY (partition_date INT)
-- CLUSTERED BY (status) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_NC_taxonomy'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_NC_taxonomy`;