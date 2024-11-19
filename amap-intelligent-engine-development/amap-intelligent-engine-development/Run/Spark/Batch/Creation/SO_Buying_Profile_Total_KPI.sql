CREATE TABLE IF NOT EXISTS `Buying_Profile_Total_KPI` (
    `advertiser_id` STRING,
    `advertiser_name` STRING,
    `brand_name` STRING,
    `brand_id` STRING,
	`industry` STRING,
    `audience` STRING,
    `cp_total_audience` DOUBLE,
    `avg_daily_budget` DOUBLE,    
    `avg_lines` DOUBLE
  --  `discount` DOUBLE,
  --  `objective` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (brand_name) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/Buying_Profile_Total_KPI'
TBLPROPERTIES("transactional"="true");

msck repair table `Buying_Profile_Total_KPI`;
