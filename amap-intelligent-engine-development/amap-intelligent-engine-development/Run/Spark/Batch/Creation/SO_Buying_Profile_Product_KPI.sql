CREATE TABLE IF NOT EXISTS `Buying_Profile_Product_KPI` (
    `advertiser_id` STRING,
    `advertiser_name` STRING,
    `brand_name` STRING,
    `brand_id` STRING,
    `catalog_level` INT,
    `industry` STRING,
    `record_type` STRING,    
    `media_type` STRING,
    `length` INT,
    `display_name` STRING,    
    `perc_value` DOUBLE,
    `market_product_type_id` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (record_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/Buying_Profile_Product_KPI'
TBLPROPERTIES("transactional"="true");

msck repair table `Buying_Profile_Product_KPI`;