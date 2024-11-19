CREATE TABLE IF NOT EXISTS `STG_DMP_AudienceSegmentMap` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `krux_userid` STRING,
    `publisher_userid` STRING,
    `dmp_segment_id` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (publisher_userid) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_DMP_AudienceSegmentMap'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_DMP_AudienceSegmentMap`;