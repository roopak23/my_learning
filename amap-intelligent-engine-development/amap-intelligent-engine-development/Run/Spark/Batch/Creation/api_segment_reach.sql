CREATE TABLE IF NOT EXISTS `api_segment_reach` (
	`adserver_id` STRING,
	`commercial_audience_name` STRING,
    `adserver_target_remote_id` STRING,
    `adserver_target_name` STRING,
    `reach` int,
    `impression` int,
    `spend` Double
)
PARTITIONED BY (partition_date INT)
-- CLUSTERED BY (status) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/api_segment_reach'
TBLPROPERTIES("transactional"="true");

msck repair table `api_segment_reach`;