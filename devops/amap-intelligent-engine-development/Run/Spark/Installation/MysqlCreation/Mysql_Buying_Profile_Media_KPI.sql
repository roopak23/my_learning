-- data_activation.Buying_Profile_Media_KPI definition
CREATE TABLE if not exists `Buying_Profile_Media_KPI` (
  `advertiser_id` varchar(100) ,
  `advertiser_name` varchar(255) DEFAULT NULL,
  `brand_name` varchar(255),
  `brand_id` varchar(100),
  `industry` varchar(255) DEFAULT NULL,
  `media_type` varchar(100) ,
  `unit_of_measure` varchar(50),
  `desired_metric_daily_avg` int DEFAULT 0,
  `cp_media_type` double DEFAULT NULL,
  `desired_avg_budget_daily` double DEFAULT NULL,
  `avg_lines` double DEFAULT NULL,
  `selling_type` varchar(50),
  `media_perc` double DEFAULT NULL,
  `market_product_type_id` varchar(100),
  `discount` double DEFAULT NULL,
  `objective` varchar(255) DEFAULT NULL,
primary key(`advertiser_id`, `brand_id`, `media_type`,`market_product_type_id`,`unit_of_measure`,`selling_type`)
) ;
