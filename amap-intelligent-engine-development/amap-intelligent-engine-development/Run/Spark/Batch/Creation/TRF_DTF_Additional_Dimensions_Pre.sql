CREATE TABLE IF NOT EXISTS `TRF_DTF_Additional_Dimensions_Pre` (
	`date` DATE,
	`adserver_id` STRING,
	`adserver_adslot_id` STRING,
	`adserver_adslot_name` STRING,
	`advertiser_id` STRING,
	`remote_id` STRING,
	`country` STRING,
	`State` STRING,
	`city` STRING,
	`platform_name` STRING,
	`impressions` INT,
	`event` STRING,
	`pod_position` STRING,
	`video_position` STRING,
	`audience_name` STRING,
	`selling_type` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (record_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_DTF_Additional_Dimensions_Pre';

msck repair table `TRF_DTF_Additional_Dimensions_PRE`;
