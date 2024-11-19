CREATE TABLE IF NOT EXISTS `industry_benchmark` (
  `id` varchar(255) NOT NULL,
  `industry_name` varchar(255) DEFAULT NULL,
  `system_id` varchar(255) DEFAULT NULL,
  `system_name` varchar(255) DEFAULT NULL,
  `cpm` double DEFAULT 0.0,
  `cpc` double DEFAULT 0.0,
  `ctr` double DEFAULT 0.0,
  PRIMARY KEY (`id`)
);