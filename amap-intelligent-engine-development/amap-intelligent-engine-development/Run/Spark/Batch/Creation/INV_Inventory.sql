CREATE TABLE IF NOT EXISTS `Inventory` (
    `date` Date,
	`metric` STRING,
    `adserver_id` STRING,
	`adslot_id` STRING,
	`adserver_adslot_name` STRING,
	`adformat_id` STRING,
	`sitepage` STRING,
	`adserver_target_remote_id` STRING,
	`adserver_target_name` STRING,
	`adserver_target_type` STRING,
	`adserver_target_category` STRING,
	`adserver_target_code` STRING,
	`future_capacity` INT,
    `booked` INT
)
--PARTITIONED BY (partition_date INT)
--CLUSTERED BY (metric) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/Inventory'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `Inventory`;
