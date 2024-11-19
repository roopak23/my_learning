CREATE TABLE IF NOT EXISTS `STG_AdServer_AudienceSegment` (
	`sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
	`adserver_id` STRING,
    `adserver_target_remote_id` STRING,
    `adserver_target_name` STRING,
    `adserver_target_type` STRING,
    `status` STRING,
    `dataprovider` STRING,
    `segment_type` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (segment_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_AdServer_AudienceSegment'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_AdServer_AudienceSegment`;