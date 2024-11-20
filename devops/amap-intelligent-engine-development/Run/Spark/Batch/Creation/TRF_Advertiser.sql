CREATE TABLE IF NOT EXISTS `TRF_Advertiser` (
    `advertiser_id` STRING,
    `advertiser_name` STRING,
    `record_type` STRING,
    `industry` STRING,
    `brand_name` STRING,
    `brand_id` STRING,
    `adserver_id` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (record_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Advertiser'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_Advertiser`;