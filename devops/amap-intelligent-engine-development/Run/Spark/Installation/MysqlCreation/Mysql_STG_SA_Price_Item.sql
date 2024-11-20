CREATE TABLE if not exists `STG_SA_Price_Item` (
  `price_item_id` varchar(255),
  `catalog_item_id` varchar(255) DEFAULT NULL,
  `currency` varchar(255) DEFAULT NULL,
  `commercial_audience` varchar(255) DEFAULT NULL,
  `price_list` varchar(150) DEFAULT NULL,
  `price_per_unit` double DEFAULT NULL,
  `spot_length` double DEFAULT NULL,
  `unit_of_measure` varchar(255) DEFAULT NULL,
  `datasource` varchar(255) DEFAULT NULL,
  primary key(price_item_id)
) ;