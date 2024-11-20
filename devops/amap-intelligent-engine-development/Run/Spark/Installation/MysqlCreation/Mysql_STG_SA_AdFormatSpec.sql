-- data_activation.STG_SA_AdFormatSpec definition

CREATE TABLE IF NOT EXISTS `STG_SA_AdFormatSpec` (
  `afsid` varchar(255) ,
  `ad_format_id` varchar(255) DEFAULT NULL,
  `catalog_item_id` varchar(255) ,
  `breadcrumb` varchar(255) DEFAULT NULL,
  `datasource` varchar(255) DEFAULT NULL,
  primary key(afsid,catalog_item_id)
) ;