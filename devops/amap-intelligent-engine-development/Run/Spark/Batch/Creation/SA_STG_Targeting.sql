CREATE TABLE IF NOT EXISTS `STG_SA_Targeting` (
	`sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
	`target_id` STRING,
	`adserver_target_type` STRING,
	`adserver_target_remote_id` STRING,
	`adserver_target_name` STRING,
	`adserver_id` STRING,
	`adserver_target_category` STRING,
	`adserver_target_code` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (adserver_target_category) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_Targeting'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_SA_Targeting`;
