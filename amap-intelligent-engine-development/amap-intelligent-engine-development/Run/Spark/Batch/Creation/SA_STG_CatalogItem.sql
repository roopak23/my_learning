CREATE TABLE IF NOT EXISTS `STG_SA_CatalogItem` (
	`sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
	`catalog_item_id` STRING,
	`name` STRING,
	`parent_id` STRING,
	`display_name` STRING,
	`media_type` STRING,
	`catalog_level` INT,
	`record_type` STRING,
	`commercial_audience` STRING,
	`age` STRING,
	`gender` STRING,
	`interest` STRING,
	`objective` STRING,
	`adserver_id` STRING,
	`Catalog_Full_Path` STRING
	)
PARTITIONED BY (partition_date INT)
-- CLUSTERED BY (media_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_CatalogItem'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `STG_SA_CatalogItem`;
