CREATE TABLE IF NOT EXISTS `TRF_InvFutureSegment` (
    `date` DATE,
    `adserver_id` STRING,
    `adserver_adslot_id` STRING,
    `metric` STRING,
    `city` STRING,
    `State` STRING,
    `event` STRING,
    `forcasted` INT,
    `booked` INT,
    `available` INT
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (adserver_target_category) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_InvFutureSegment'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_InvFutureSegment`;