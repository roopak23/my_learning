-- data_activation.Buying_Profile_Product_KPI definition

CREATE TABLE if not exists `Buying_Profile_Product_KPI` (
  `advertiser_id` varchar(100) ,
  `advertiser_name` varchar(150) DEFAULT NULL,
  `brand_name` varchar(255) ,
  `brand_id` varchar(100) ,
  `catalog_level` int DEFAULT NULL,
  `industry` varchar(255) DEFAULT NULL,
  `record_type` varchar(100) ,
  `media_type` varchar(100) ,
  `length` int DEFAULT NULL,
  `display_name` varchar(100) ,
  `perc_value` double DEFAULT NULL,
  primary key(`advertiser_id`, `brand_id`, `record_type`,`media_type`,`display_name`)
) ;
