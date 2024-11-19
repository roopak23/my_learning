CREATE TABLE IF NOT EXISTS `TRF_DMP_AudienceSegmentMapNormalize` (
    `sys_datasource` STRING,
    `krux_userid` STRING,
    `publisher_userid` STRING,
    `dmp_segment_id` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (dmp_segment_id) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_DMP_AudienceSegmentMapNormalize'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_DMP_AudienceSegmentMapNormalize`;  