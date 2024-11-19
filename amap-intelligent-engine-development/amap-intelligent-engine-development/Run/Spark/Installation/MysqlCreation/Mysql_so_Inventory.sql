-- data_activation.so_inventory definition

CREATE TABLE IF NOT EXISTS `so_inventory` (
  `date` datetime NOT NULL,
  `adserver_adslot_id` varchar(50) NOT NULL,
  `adserver_id` varchar(50)NOT NULL,
  `metric` varchar(50) NOT NULL,
  `media_type` varchar(255) DEFAULT NULL,
  `catalog_value` varchar(255) DEFAULT NULL,
  `record_type` varchar(255) DEFAULT NULL,
  `catalog_item_id` varchar(50),
  `catalog_item_name` varchar(255) DEFAULT NULL,
  `future_capacity` int DEFAULT NULL,
  `booked` int DEFAULT NULL,
  `reserved` int DEFAULT NULL,
  PRIMARY KEY (`date`,`adserver_adslot_id`,`adserver_id`,`metric`,`catalog_item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8  COLLATE=utf8_general_ci;
