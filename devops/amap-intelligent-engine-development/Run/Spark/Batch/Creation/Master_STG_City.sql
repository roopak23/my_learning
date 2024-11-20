CREATE TABLE IF NOT EXISTS `STG_Master_City` (
	`sys_datasource` STRING,
	`sys_load_id` BIGINT,
	`sys_created_on` TIMESTAMP,
	`Geography` STRING,
	`State` STRING,
	`City` STRING
)
--CLUSTERED BY (status) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_Master_City'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_Master_City`;