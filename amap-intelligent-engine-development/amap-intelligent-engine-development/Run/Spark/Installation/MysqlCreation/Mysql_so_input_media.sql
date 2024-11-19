CREATE TABLE if not exists `so_input_media` (
  `simulation_id` varchar(255) ,
  `advertiser_id` varchar(255),
  `industry` varchar(255) DEFAULT NULL,
  `advertiser_name` varchar(255) DEFAULT NULL,
  `media_type` varchar(255) ,
  `desired_budget_media_type` double DEFAULT NULL,
  `desired_metric_media_type` int DEFAULT NULL,
  `unit_of_measure_media_type` varchar(255) DEFAULT NULL,
  `cp_media_type` double DEFAULT NULL,
  `monday` int(11) DEFAULT NULL,
  `tuesday` int(11) DEFAULT NULL,
  `wednesday` int(11) DEFAULT NULL,
  `thursday` int(11) DEFAULT NULL,
  `friday` int(11) DEFAULT NULL,
  `saturday` int(11) DEFAULT NULL,
  `sunday` int(11) DEFAULT NULL,
  `brand_name` varchar(255) DEFAULT NULL,
  `selected` int DEFAULT NULL,
  primary key(simulation_id,advertiser_id,media_type)
) ;