CREATE TABLE if not exists `Buying_Profile_Total_KPI` (
  `advertiser_id` varchar(100) ,
  `advertiser_name` varchar(255) DEFAULT NULL,
  `brand_name` varchar(255) ,
  `brand_id` varchar(100) ,
  `industry` varchar(100) ,
  `audience` varchar(255) ,
  `cp_total_audience` double DEFAULT NULL,
  `avg_daily_budget` double DEFAULT NULL,
  `avg_lines` double,
 -- `discount` double DEFAULT NULL,
--  `objective` varchar(255) DEFAULT NULL,
 primary key(`advertiser_id`, `brand_id`, `industry`)
 ) ;
-- ,`audience` to be added in PK and avg_lines to be deleted from PK
