CREATE TABLE IF NOT EXISTS `TRF_Fact_Input` (
	`tech_line_id` STRING,
	`tech_order_id` STRING,
	`date` DATE,
	`running_days_elapsed` INT,
	`remaining_days` INT,
	`system_id` STRING,
	`metric` STRING,
	`daily_quantity_expected` INT,
	`cumulative_quantity_expected` INT,
	`cumulative_quantity_delivered` INT,
	`relative_quantity_delivered` DOUBLE,
	`delta_quantity` INT,
	`delta_perc` INT,
	`status` STRING,
	`budget_cumulative_delivered` DOUBLE,
	`budget_cumulative_expected` DOUBLE,
	`budget_daily_delivered` DOUBLE,
	`remaining_budget` DOUBLE,
	`daily_expected_pacing` DOUBLE,
	`actual_pacing` DOUBLE,
	`flag_optimisation_temp` STRING,
	`flag_optimisation` STRING,
	`remote_id` STRING,
	`unit_type` STRING,
	`predicted_units` INT,
	`quantity_delivered` INT,
	`matched_units` INT,
	`forecasted_quantity` INT,
	`forecasted_pacing` DOUBLE
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Fact_Input'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_Fact_Input`;