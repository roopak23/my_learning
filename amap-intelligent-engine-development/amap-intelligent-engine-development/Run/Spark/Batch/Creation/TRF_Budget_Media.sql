CREATE TABLE IF NOT EXISTS `TRF_Budget_Media` (
    `advertiser_id` STRING,
    `advertiser_name` STRING,
    `brand_name` STRING,
    `brand_id` STRING,
    `industry` STRING,
    `media_type` STRING,
    `unit_of_measure` STRING,
    `cp_media_type` DOUBLE,
    `desired_avg_budget_daily` DOUBLE,
    `avg_lines` DOUBLE,
    `selling_type` STRING,
    `market_product_type_id` STRING,
    `media_perc` DOUBLE,
    `discount` DOUBLE,
    `objective` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (media_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Budget_Media'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_Budget_Media`;
