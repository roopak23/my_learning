CREATE TABLE IF NOT EXISTS `STG_AdServer_AdSlot` (
	`sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
	`adserver_id` STRING,
    `adserver_adslot_id` STRING,
    `adserver_adslot_name` STRING,
    `sitepage` STRING,
    `status` STRING,
    `adserver_parent_id` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (status) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_AdServer_AdSlot'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_AdServer_AdSlot`;