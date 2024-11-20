CREATE TABLE IF NOT EXISTS `TRF_AdServer_InvFuture` (
    `date` date,
    `booked` INT,
    `adserver_adslot_id` STRING,
    `adserver_id` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (metric) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_AdServer_InvFuture'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_AdServer_InvFuture`;