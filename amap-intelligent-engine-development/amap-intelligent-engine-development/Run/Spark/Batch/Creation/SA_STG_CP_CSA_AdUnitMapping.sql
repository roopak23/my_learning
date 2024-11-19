CREATE TABLE IF NOT EXISTS `STG_SA_CP_CSA_AdUnitMapping` (
	`sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
	`Common_Sales_Area` STRING,
	`Content_Partner` STRING,
	`Platfor_Name` STRING,
	`adserver_adslot_name_1` STRING,
	`adserver_adslot_name_2` STRING,
	`adserver_adslot_name_3` STRING,
	`adserver_adslot_name_4` STRING,
	`adserver_adslot_name_5` STRING,
	`adserver_adslot_id_1` STRING,
	`adserver_adslot_id_2` STRING,
	`adserver_adslot_id_3` STRING,
	`adserver_adslot_id_4` STRING,
	`adserver_adslot_id_5` STRING
	)
PARTITIONED BY (partition_date INT)
-- CLUSTERED BY (media_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_CP_CSA_AdUnitMapping'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `STG_SA_CP_CSA_AdUnitMapping`;
