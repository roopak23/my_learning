-- data_activation.STG_SA_CatalogItem definition

CREATE TABLE IF NOT EXISTS `STG_SA_CatalogItem` (
  `catalog_item_id` varchar(255) ,
  `name` varchar(255) DEFAULT NULL,
  `parent_id` varchar(255) DEFAULT NULL,
  `display_name` varchar(255) DEFAULT NULL,
  `media_type` varchar(255) DEFAULT NULL,
  `catalog_level` int(11) DEFAULT NULL,
  `record_type` varchar(255) DEFAULT NULL,
  `commercial_audience` varchar(255) DEFAULT NULL,
  `age` varchar(255) DEFAULT NULL,
  `gender` varchar(255) DEFAULT NULL,
  `interest` varchar(255) DEFAULT NULL,
  `objective` varchar(255) DEFAULT NULL,
  `adserver_id` varchar(255) DEFAULT NULL,
  `catalog_full_path` varchar(255) DEFAULT NULL,
  `datasource` varchar(255) DEFAULT NULL,
  primary key(catalog_item_id)
) ;
