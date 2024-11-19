CREATE TABLE IF NOT EXISTS `STG_SA_Market_Targeting` (
`sys_datasource` STRING,
`sys_load_id` BIGINT,
`sys_created_on` TIMESTAMP,
`target_name` STRING,
`target_type` STRING,
`target_id` STRING,
`commercial_audience_id` STRING,
`commercial_audience_name` STRING
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_Market_Targeting'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `STG_SA_Market_Targeting`;