CREATE TABLE IF NOT EXISTS `trf_adserver_forecast_input` (
	`tech_line_id` STRING,
	`remote_id` STRING,
	`tech_order_id` STRING,
	`order_remote_id` STRING,
	`model_id` STRING,
	`start_date` DATE,
	`end_date` DATE,
	`product_suggestion` STRING,
	`adserver_target_type` STRING,
	`audience_suggestion` STRING,
	`priority_suggestion` INT,
	`frequency_capping` STRING,
	`frequency_suggestion` INT,
	`cost_per_unit` DOUBLE,
	`metric` STRING,
	`campaign_objective` STRING,
	`creative_size` STRING
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/trf_adserver_forecast_input'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `trf_adserver_forecast_input`;