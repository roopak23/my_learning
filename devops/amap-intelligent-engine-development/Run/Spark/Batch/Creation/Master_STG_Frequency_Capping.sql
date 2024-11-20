CREATE TABLE IF NOT EXISTS `STG_Frequency_Capping` (
	`sys_datasource` STRING,
	`sys_load_id` BIGINT,
	`sys_created_on` TIMESTAMP,
	`adserver_adslot_id` STRING,
	`adserver_adslot_name` STRING,
	`time_unit` STRING,
	`num_time_units` INT,
	`max_impressions` INT,
	`factor` DOUBLE
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (status) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_Frequency_Capping'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_Frequency_Capping`;