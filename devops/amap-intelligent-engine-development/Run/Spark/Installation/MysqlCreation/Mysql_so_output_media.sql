CREATE TABLE IF NOT EXISTS `so_output_media` (
    `simulation_id` varchar(150),
    `advertiser_id` varchar(150),
    `advertiser_name` varchar(255),
    `brand_name` varchar(100),
    `media_type` varchar(100),
    `budget_media_type` double,
    `metric_media_type` varchar(255),
    `unit_of_measure_media_type` varchar(255),
    `cp_media` DOUBLE,    
    `total_audience` varchar(255),
    primary key(simulation_id,advertiser_id,media_type)
);
