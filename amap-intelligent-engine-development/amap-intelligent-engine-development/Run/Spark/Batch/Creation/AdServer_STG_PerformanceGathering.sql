CREATE TABLE IF NOT EXISTS `STG_AdServer_PerformanceGathering` (
	`sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
	`date` DATE,
	`adserver_adslot_id` STRING,
	`adserver_adslot_name` STRING,
	`adserver_target_remote_id` STRING,
	`adserver_target_name` STRING,
	`impressions` INT,
	`clicks` INT,
	`adserver_id` STRING,
	`adserver_target_type` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (adserver_target_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_AdServer_PerformanceGathering'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `STG_AdServer_PerformanceGathering`;