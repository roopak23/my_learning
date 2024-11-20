CREATE TABLE IF NOT EXISTS `TRF_Days_Order_Avg` (
    `advertiser_id` STRING,
    `advertiser_name` STRING,
    `brand_name` STRING,
    `brand_id` STRING,
    `industry` STRING,
    `market_order_id` STRING,
    `budget_order` DOUBLE,
    `count_days` INT,
    `count_lines` INT,
    `daily_budget` DOUBLE
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (brand_name) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Days_Order_Avg'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_Days_Order_Avg`;