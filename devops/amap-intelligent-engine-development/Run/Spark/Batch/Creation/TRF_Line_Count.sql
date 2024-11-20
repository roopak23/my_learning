CREATE TABLE IF NOT EXISTS `TRF_Line_Count` (
    `advertiser_id` STRING,
    `advertiser_name` STRING,
    `brand_name` STRING,
    `brand_id` STRING,
    `media_type` STRING,
    `unit_type` STRING,
    `count_lines` INT,
    `market_product_type_id` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (media_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Line_Count'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_Line_Count`;
