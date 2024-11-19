CREATE TABLE IF NOT EXISTS `TRF_Historical_capacity` (
    `date` DATE,
    `adserver_id` STRING,
    `adserver_adslot_id` STRING,
    `adserver_adslot_name` STRING,
    `adserver_target_remote_id` STRING,
    `adserver_target_name` STRING,
    `unfilled_metric` DOUBLE,
	`metric` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (adserver_target_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Historical_capacity'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_Historical_Capacity`;
