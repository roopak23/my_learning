CREATE TABLE IF NOT EXISTS `TRF_Industry_Insights` (
	`date` STRING,
	`industry` STRING,
	`channel` STRING,
	`media_type` STRING,
	`report_id` STRING,
	`cpc` DOUBLE,
	`ctr` DOUBLE,
	`cpcv` DOUBLE,
	`cpv` DOUBLE,
	`cpm` DOUBLE,
	`view_rate` DOUBLE,
	`impressions` INT,
	`player_25` INT,
	`player_50` INT,
	`player_75` INT,
	`player_100` INT,
	`post_engagement` INT,
	`time_of_day` STRING,
	`day_of_week` STRING,
	`device` STRING,
	`gender` STRING,
	`age` STRING,
	`keyword` STRING,
	`display_format` STRING,
	`social_placement` STRING,
	`network_type` STRING,
	`country` STRING,
	`state` STRING,
	`region` STRING,
	`city` STRING,
	`email_total_sent` DOUBLE,
	`unique_open_rate` DOUBLE,
	`unique_click_rate` DOUBLE,
	`sms_total_sent` DOUBLE
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Industry_Insights'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `TRF_Industry_Insights`;