CREATE TABLE IF NOT EXISTS `TRF_Days_Line` (
    `advertiser_id` STRING,
    `advertiser_name` STRING,
    `brand_name` STRING,
    `brand_id` STRING,
    `industry` STRING,
    `market_order_line_details_id` STRING,
    `media_type` STRING,
    `unit_type` STRING,
    `total_price` DOUBLE,
    `count_days` INT,
    `market_product_type_id` STRING,
    `discount` DOUBLE,
    `objective` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (media_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Days_Line'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_Days_Line`;
