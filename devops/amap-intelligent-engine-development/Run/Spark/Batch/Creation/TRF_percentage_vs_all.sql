CREATE TABLE IF NOT EXISTS `TRF_percentage_vs_all` (
	`adserver_id` STRING,
	`adserver_adslot_id` STRING,
	`adserver_target_remote_id` STRING,
	`adserver_target_name` STRING,
	`ratio` DOUBLE
)
--PARTITIONED BY (partition_date INT)
--CLUSTERED BY (adserver_target_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_percentage_vs_all'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `TRF_percentage_vs_all`;