CREATE TABLE IF NOT EXISTS `TRF_Product` (
	`catalog_item_id ` STRING,
	`ad_format_id` STRING,
	`breadcrumb` STRING,
	`audience_list` STRING,
	`objective_list` STRING,
	`unit_price` DOUBLE,
	`media_type` STRING,
	`size` STRING,
	`metric` STRING,
	`adserver_id` STRING
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Product'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_Product`;