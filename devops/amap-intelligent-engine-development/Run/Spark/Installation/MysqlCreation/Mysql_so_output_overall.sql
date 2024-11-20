CREATE TABLE IF NOT EXISTS `so_output_overall` (
  `simulation_id` varchar(255) NOT NULL,
  `advertiser_id` varchar(255) NOT NULL,
  `advertiser_name` varchar(255) DEFAULT NULL,
  `brand_name` varchar(255) NOT NULL,
  `total_audience` varchar(255) DEFAULT NULL,
  `budget_total` double DEFAULT NULL,
  `audience` varchar(255) NOT NULL,
  `cp_total_audience` double DEFAULT NULL,
  `total_quantity` double DEFAULT NULL,
  `brand_id` varchar(150) DEFAULT NULL,
  `objective` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`simulation_id`,`advertiser_id`,`audience`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;