CREATE TABLE IF NOT EXISTS `TRF_Advertiser_Spec_Total` (
    `advertiser_id` STRING,
    `advertiser_name` STRING,
    `brand_name` STRING,
    `industry` STRING,
    `market_order_line_details_id` STRING,
    `catalog_level` STRING,
    `record_type` STRING,
    `media_type` STRING,
    `length` INT,
    `display_name` STRING,
    `perc_price` DOUBLE,
    `market_product_type_id` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (record_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Advertiser_Spec_Total'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_Advertiser_Spec_Total`;