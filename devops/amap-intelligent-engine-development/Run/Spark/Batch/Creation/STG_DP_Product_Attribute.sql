CREATE TABLE IF NOT EXISTS `STG_DP_Product_Attribute` (
	`sys_datasource` STRING,
	`sys_load_id` BIGINT,
	`sys_created_on` TIMESTAMP,
	`product_id` STRING,
	`attribute_name` STRING,
	`attribute_value` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (metric) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_DP_Product_Attribute'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_DP_Product_Attribute`;