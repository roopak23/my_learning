CREATE TABLE if not exists `so_input_product` (
  `simulation_id` varchar(150) ,
  `advertiser_id` varchar(150) ,
  `advertiser_name` varchar(255) DEFAULT NULL,
  `catalog_level` int DEFAULT NULL,
  `record_type` varchar(100) ,
  `perc_value` double DEFAULT NULL,
  `media_type` varchar(100) ,
  `catalog_item_id` varchar(255) DEFAULT NULL,
  `length` int DEFAULT NULL,
  `display_name` varchar(100) ,
  `brand_name` varchar(100) ,
  primary key(simulation_id,advertiser_id,record_type,media_type,display_name,brand_name)
) ;