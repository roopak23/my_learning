CREATE TABLE IF NOT EXISTS `TRF_Advertiser_Spec` (
    `advertiser_id` STRING,
    `advertiser_name` STRING,
    `brand_name` STRING,
    `industry` STRING,
    `market_order_line_details_id` STRING,
    `catalog_level` STRING,
    `record_type` STRING,
    `media_type` STRING,
    `length` STRING,
    `display_name` STRING,
    `budget` DOUBLE,
    `market_product_type_id` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (media_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Advertiser_Spec'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_Advertiser_Spec`;
