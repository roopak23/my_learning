CREATE TABLE IF NOT EXISTS `STG_DP_Adserver_Segment_Mapping` (
	`sys_datasource` STRING,
	`sys_load_id` BIGINT,
	`sys_created_on` TIMESTAMP,
	`segment_id` STRING,
	`segment_name` STRING,
	`techincal_remote_id` STRING,
	`techincal_remote_name` STRING,
	`adserver_id` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (metric) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_DP_Adserver_Segment_Mapping'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_DP_Adserver_Segment_Mapping`;