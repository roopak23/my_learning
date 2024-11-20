CREATE TABLE IF NOT EXISTS `TRF_GADS` (
	`date` DATE,
	`creation_date` DATE,
	`tech_order_id` STRING,
	`tech_line_id` STRING,
	`remote_id` STRING,
	`report_id` STRING,
	`system_id` STRING,
	`ad_server_type` STRING,
	`start_date` DATE,
	`end_date` DATE,
	`total_line_spend` DOUBLE,
	`total_order_spend` DOUBLE,
	`total_price` DOUBLE,
	`gads_pacing` DOUBLE
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_GADS'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `TRF_GADS`;