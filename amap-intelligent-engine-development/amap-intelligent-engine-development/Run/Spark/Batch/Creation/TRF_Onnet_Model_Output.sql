CREATE TABLE IF NOT EXISTS `TRF_Onnet_Model_Output` (
	`tech_line_id` STRING,
	`tech_order_id` STRING,
	`unit_type` STRING,
	`model_id` STRING,
	`optimization_type` STRING,
	`technical_id` STRING,
	`commercial_id` STRING,
	`original_value` STRING,
	`original_predicted_units` INT
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Onnet_Model_Output'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_Onnet_Model_Output`;