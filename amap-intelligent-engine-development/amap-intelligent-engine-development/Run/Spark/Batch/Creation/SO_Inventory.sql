CREATE TABLE IF NOT EXISTS `SO_Inventory` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `date` DATE,
    `adserver_adslot_id` STRING,
    `adserver_id` STRING,
    `metric` STRING,
    `media_type` STRING,
    `catalog_value` STRING,
    `record_type` STRING,
	`catalog_item_id` STRING,
    `catalog_item_name` STRING,
    `adserver_target_remote_id` STRING,
    `adserver_target_name` STRING,
    `adserver_target_type` STRING,
    `adserver_target_category` STRING,
    `adserver_target_code` STRING,
    `future_capacity` INT,
    `booked` INT,
    `reserved` INT
    )
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/SO_Inventory'
TBLPROPERTIES("transactional"="true");

msck repair table `SO_Inventory`;