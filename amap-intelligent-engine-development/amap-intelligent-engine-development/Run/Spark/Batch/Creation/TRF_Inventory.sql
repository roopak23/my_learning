-- data_activation.TRF_Inventory definition

CREATE TABLE IF NOT EXISTS `TRF_Inventory` (
	`date` DATE,
	`adserver_id` STRING,
	`adserver_adslot_id` STRING,
	`adserver_adslot_name` STRING,
	`metric` STRING,
	`state` STRING,
	`city` STRING,
	`event` STRING,
	`pod_position` STRING,
	`video_position` STRING,
	`future_capacity` DOUBLE,
	`booked` DOUBLE
 )
PARTITIONED BY (partition_date INT) 
STORED AS ORC LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Inventory';

MSCK REPAIR TABLE `TRF_Inventory`;
