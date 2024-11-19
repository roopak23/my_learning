CREATE TABLE IF NOT EXISTS `trf_adserver_forecast_output` (
	`remote_id` STRING,
	`order_remote_id` STRING,
	`unit_type` STRING,
	`predicted_units` INT,
	`quantity_delivered` INT,
	`matched_units` INT,
	`model_id` STRING
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/trf_adserver_forecast_output'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `trf_adserver_forecast_output`;