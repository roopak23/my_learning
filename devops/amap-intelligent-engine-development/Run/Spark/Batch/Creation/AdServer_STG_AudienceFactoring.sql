CREATE TABLE IF NOT EXISTS `STG_AdServer_AudienceFactoring` (
	`sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
	`platform_name` STRING,
    `dimension_level` STRING,
    `dimension` STRING,
    `audience_name` STRING,
    `% audience` INT
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (segment_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_AdServer_AudienceFactoring'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_AdServer_AudienceFactoring`;