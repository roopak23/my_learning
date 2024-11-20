SELECT 
	`catalog_item_id`,
    `name`,
    `parent_id`,
    `display_name`,
    `media_type`,
    `catalog_level`,
    `record_type`,
	`commercial_audience`,
    `age`,
    `gender`,
    `interest`,
    `objective`,
    `adserver_id`,
	`catalog_full_path`,
	`sys_datasource`
FROM STG_SA_CatalogItem
WHERE partition_date = (SELECT MAX(partition_date) FROM STG_SA_CatalogItem)


