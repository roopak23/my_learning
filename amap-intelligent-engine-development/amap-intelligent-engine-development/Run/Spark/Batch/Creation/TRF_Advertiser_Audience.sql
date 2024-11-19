CREATE TABLE IF NOT EXISTS `TRF_Advertiser_Audience` (
    `advertiser_id` STRING,
    `brand_id` STRING,
    `advertiser_name` STRING,
    `brand_name` STRING,
    `commercial_audience` STRING,
    `total_price` DOUBLE
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (brand_name) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Advertiser_Audience'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_Advertiser_Audience`;