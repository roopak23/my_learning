CREATE TABLE IF NOT EXISTS `so_output_product` (
    `simulation_id` varchar(150),
    `advertiser_id` varchar(150),
    `advertiser_name` varchar(255),
    `brand_name` varchar(100),
    `catalog_level` INT,
    `record_type` varchar(100),
    `perc_value` double,  
    `media_type` varchar(100),
    `catalog_item_id` varchar(255), 
    `length` INT,
    `display_name` varchar(150),    
    `status` varchar(255),
    primary key(simulation_id,advertiser_id,record_type,media_type,display_name)
);