CREATE TABLE IF NOT EXISTS `ML_InvForecastingOutputSegment` (
    `date` Date,
    `adserver_adslot_id` STRING,
    `adserver_id` STRING,
	`adserver_target_remote_id` STRING,
    `adserver_target_name` STRING,
	`adserver_target_type` STRING,
	`adserver_target_category` STRING,
	`adserver_target_code` STRING,
	`metric` STRING,
	`future_capacity` INT
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (adserver_target_category) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/ML_InvForecastingOutputSegment'
TBLPROPERTIES("transactional"="true");
MSCK REPAIR TABLE `ML_InvForecastingOutputSegment`;
