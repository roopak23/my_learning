CREATE TABLE IF NOT EXISTS `ML_product_recommendation` (
  `simulation_id` varchar(150) NOT NULL, 
  `advertiser_id` varchar(150) NOT NULL,
  `brand_id` varchar(150) NOT NULL,
  `start_date` date,
  `end_date` date,
  `format_id` varchar(150) NOT NULL,
  `score` double DEFAULT NULL,
  `score_raw` double DEFAULT NULL,
  `gads_bidding_strategy` varchar(255) DEFAULT NULL,
  PRIMARY KEY(`simulation_id`)
);
