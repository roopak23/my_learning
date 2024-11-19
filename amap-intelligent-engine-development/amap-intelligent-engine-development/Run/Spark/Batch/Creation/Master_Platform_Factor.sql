CREATE TABLE IF NOT EXISTS `STG_AdServer_Platform_Factor` (
	`sys_datasource` STRING,
	`sys_load_id` BIGINT,
	`sys_created_on` TIMESTAMP,
	`platform_name` STRING,
	`ssp_factor` DOUBLE
)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_AdServer_Platform_Factor'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_AdServer_Platform_Factor`;