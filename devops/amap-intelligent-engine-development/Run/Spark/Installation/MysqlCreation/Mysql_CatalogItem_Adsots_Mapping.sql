-- data_activation.CatalogItem_Adsots_Mapping definition

CREATE TABLE IF NOT EXISTS `CatalogItem_Adsots_Mapping` (
  `adserver_id` varchar(255) ,
  `catalog_item_name` varchar(50) ,
  `display_name` varchar(255),
  `catalog_full_path` varchar(255),
  `adserver_adslot_id` varchar(50),
  `adserver_adslot_name` varchar(100)
) ;
