CREATE TABLE IF NOT EXISTS `STG_AdServer_InvFuture_Next_3_Months` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `date` date,
    `adserver_adslot_id` STRING,
    `adserver_adslot_name` STRING,
    `forcasted` INT,
    `booked` INT,
    `available` INT,
	`adserver_id` STRING,
    `metric` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (metric) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_AdServer_InvFuture_Next_3_Months'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_AdServer_InvFuture_Next_3_Months`;