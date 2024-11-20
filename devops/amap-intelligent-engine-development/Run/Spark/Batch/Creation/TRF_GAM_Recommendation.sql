CREATE TABLE IF NOT EXISTS `TRF_GAM_Recommendation` (
	`remote_id` STRING,
	`order_remote_id` STRING,
	`unit_type` STRING,
	`predicted_units` INT,
	`quantity_delivered` INT,
	`matched_units` INT,
	`tech_line_id` STRING,
	`tech_order_id` STRING,
	`model_id` STRING,
	`optimization_type` STRING,
	`technical_id` STRING,
	`commercial_id` STRING,
	`original_value` STRING,
	`original_predicted_units` STRING
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_GAM_Recommendation'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `TRF_GAM_Recommendation`;