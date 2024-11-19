CREATE TABLE IF NOT EXISTS `trf_targeting_update` (
	`adserver_target_type` STRING,
	`adserver_target_remote_id` STRING,
    `adserver_target_name` STRING,
    `adserver_id` STRING
)
PARTITIONED BY (partition_date INT)
-- CLUSTERED BY (status) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/trf_targeting_update'
TBLPROPERTIES("transactional"="true");

msck repair table `trf_targeting_update`;