CREATE TABLE IF NOT EXISTS `TRF_GADS_Tech_Line_Forecasting` (
	`customer_id` STRING,
	`remote_id` STRING,
	`metric` STRING,
	`forecasted_quantity` INT,
	`start_date` DATE,
	`end_date` DATE,
	`unit_net_price` DOUBLE,
	`system_id` STRING
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_GADS_Tech_Line_Forecasting'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `TRF_GADS_Tech_Line_Forecasting`;