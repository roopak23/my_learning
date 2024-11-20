CREATE TABLE IF NOT EXISTS `TRF_Frequency_Capping` (
	`adserver_adslot_id` STRING,
	`adserver_adslot_name` STRING,
	`time_unit` STRING,
	`num_time_units` INT,
	`max_impressions` INT,
	`factor` DOUBLE
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (adserver_target_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Frequency_Capping'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_Frequency_Capping`;
