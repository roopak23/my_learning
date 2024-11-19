CREATE TABLE IF NOT EXISTS `TRF_InvFuture_Commercials` (
	`date` DATE,
	`adserver_adslot_id` STRING,
	`adserver_adslot_name` STRING,
	`catalog_item_id` STRING,
	`available` STRING,
	`adserver_id` STRING,
	`metric` STRING
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_InvFuture_Commercials'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `TRF_InvFuture_Commercials`;