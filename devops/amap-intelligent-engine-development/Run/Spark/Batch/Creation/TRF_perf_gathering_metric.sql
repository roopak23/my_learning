CREATE TABLE IF NOT EXISTS `TRF_perf_gathering_metric`(
	`date` DATE,
	`adserver_id` STRING,
	`adserver_adslot_id` STRING,
	`adserver_adslot_name` STRING,
	`adserver_target_remote_id` STRING,
	`adserver_target_name` STRING,
	`metric_quantity` INT,
	`metric` STRING,
	`adserver_target_type` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (adserver_target_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_perf_gathering_metric'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `TRF_perf_gathering_metric`;
