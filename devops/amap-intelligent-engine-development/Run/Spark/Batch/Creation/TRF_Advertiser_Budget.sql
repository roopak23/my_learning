CREATE TABLE IF NOT EXISTS `TRF_Advertiser_Budget` (
    `advertiser_id` STRING,
    `advertiser_name` STRING,
    `brand_name` STRING,
    `brand_id` STRING,
	`media_type` STRING,
    `total_budget` DOUBLE
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (brand_name) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Advertiser_Budget'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_Advertiser_Budget`;