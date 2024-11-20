CREATE TABLE IF NOT EXISTS `TRF_AdUnitSegmentUsage` (
    `adserver_adunit_id` STRING,
    `adserver_adslot_name` STRING,
    `adserver_id` STRING,
    `adserver_target_remote_id` STRING,
    `adserver_target_name` STRING,
    `adserver_target_type` STRING,
    `adserver_target_category` STRING,
    `adserver_target_code` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (adserver_target_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_AdUnitSegmentUsage'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_AdUnitSegmentUsage`;