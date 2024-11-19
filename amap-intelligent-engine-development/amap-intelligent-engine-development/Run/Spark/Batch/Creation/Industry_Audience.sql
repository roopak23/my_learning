CREATE TABLE IF NOT EXISTS `Industry_Audience` (
	`industry` STRING,
	`audience_id` STRING,
	`audience_name` STRING,
	`audience_frequency` INT
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/Industry_Audience'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `Industry_Audience`;