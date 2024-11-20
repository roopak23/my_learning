CREATE TABLE IF NOT EXISTS `STG_DMP_AudienceSegment` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `category` STRING,
    `subcategory` STRING,
    `segment_type` STRING,
    `segment_name` STRING,
    `dmp_segment_id` STRING,
    `dmp_segment_id_long` STRING,
	`last_compute_day` STRING,
	`description` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (category) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_DMP_AudienceSegment'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_DMP_AudienceSegment`;
