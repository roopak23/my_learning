CREATE TABLE IF NOT EXISTS `STG_DP_Purchase_Userdata` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,    
    `dp_userid` STRING,
	`purchase_date` TIMESTAMP,
    `purchase_channel` STRING,
    `purchase_amount` STRING,
    `purchase_discount` DOUBLE,
	`purchase_channel_name` STRING,
	`purchase_channel_location` STRING,
	`purchase_channel_url` STRING,
	`product_id` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (operatingsystem) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_DP_Purchase_Userdata'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_DP_Purchase_Userdata`;