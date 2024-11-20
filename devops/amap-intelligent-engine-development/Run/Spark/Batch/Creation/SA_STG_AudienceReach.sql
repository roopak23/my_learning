CREATE TABLE IF NOT EXISTS `STG_SA_AudienceReach` (
	`sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
	`commercial_audience` STRING,
    `ad_ops_system` STRING,
    `reach` int,
    `impression` int,
    `spend` Double
)
PARTITIONED BY (partition_date INT)
-- CLUSTERED BY (status) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_AudienceReach'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_SA_AudienceReach`;