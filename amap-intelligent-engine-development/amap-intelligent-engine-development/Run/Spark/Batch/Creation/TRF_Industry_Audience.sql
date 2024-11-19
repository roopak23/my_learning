CREATE TABLE IF NOT EXISTS `TRF_Industry_Audience` (
	`market_order_id ` STRING,
	`agency` STRING,
	`industry` STRING,
	`start_date` DATE,
	`end_date` DATE,
	`days_elapsed` INT,
	`audience_id` STRING,
	`audience_name` STRING,
	`audience_duration` STRING,
	`audience_frequency` INT
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Industry_Audience'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `TRF_Industry_Audience`;