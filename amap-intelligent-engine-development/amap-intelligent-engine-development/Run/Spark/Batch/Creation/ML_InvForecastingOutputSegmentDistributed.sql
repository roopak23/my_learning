CREATE TABLE IF NOT EXISTS `ML_InvForecastingOutputSegmentDistributed` (
	`date` Date,
	`adserver_id` STRING,
	`adserver_adslot_id` STRING,
	`state` STRING,
	`city` STRING,
	`event` STRING,
	`pod_position` STRING,
	`video_position` STRING,
	`metric` STRING,
	`future_capacity` DOUBLE,
	`future_capacity_adslot` DOUBLE
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (adserver_target_category) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/ML_InvForecastingOutputSegmentDistributed'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `ML_InvForecastingOutputSegmentDistributed`;
