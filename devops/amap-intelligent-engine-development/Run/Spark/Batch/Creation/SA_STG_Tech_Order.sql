CREATE TABLE IF NOT EXISTS `STG_SA_Tech_Order` (
	`sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
	`tech_order_id` STRING,
	`tech_order_name` STRING,
	`tech_order_status` STRING,
	`market_order_id` String,
	`system_id` String,
	`order_remote_id` STRING,
	`total_price` DOUBLE
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_Tech_Order'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `STG_SA_Tech_Order`;