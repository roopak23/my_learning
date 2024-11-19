-- data_activation.STG_Adserver_Audiencefactoring definition
CREATE TABLE IF NOT EXISTS `STG_Adserver_Audiencefactoring` (
  `id` INT NOT NULL,
  `platform_name` varchar(255) DEFAULT NULL,
  `dimension_level` varchar(255) DEFAULT NULL,
  `dimension` varchar(255) DEFAULT NULL,
  `audience_name` varchar(255) DEFAULT NULL,
  `% audience` INTEGER DEFAULT 0,
  PRIMARY KEY (`id`)
);