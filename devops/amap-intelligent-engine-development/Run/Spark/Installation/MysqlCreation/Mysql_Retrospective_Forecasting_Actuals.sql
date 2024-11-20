CREATE TABLE IF NOT EXISTS `Retrospective_Forecasting_Actuals` (
  `adserver_adslot_id` varchar(255) DEFAULT NULL,
  `audience_name` varchar(255) DEFAULT NULL,
  `date` date DEFAULT NULL,
  `level1` varchar(255) DEFAULT NULL,
  `level2` varchar(255) DEFAULT NULL,
  `level3` varchar(255) DEFAULT NULL,
  `level4` varchar(255) DEFAULT NULL,
  `level5` varchar(255) DEFAULT NULL,
  `state` varchar(255) DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `event` varchar(255) DEFAULT NULL,
  `capacity` int DEFAULT NULL,
  `reporttype` varchar(255) DEFAULT NULL,
  `overwritten_impressions` int DEFAULT NULL,
  partition_date varchar(255) DEFAULT NULL,
  `use_overwrite` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
