CREATE TABLE IF NOT EXISTS `ML_InvForecastingOutput` (
    `date` Date,
    `adserver_adslot_id` STRING,
    `adserver_id` STRING,
	`metric` STRING,
    `future_capacity` INT
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (metric) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/ML_InvForecastingOutput'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `ML_InvForecastingOutput`;
