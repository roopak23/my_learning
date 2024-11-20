SELECT 
    `afsid`,
    `ad_format_id`,
    `catalog_item_id`,
    `breadcrumb`,
	`sys_datasource`
FROM STG_SA_AdFormatSpec
WHERE partition_date = (SELECT MAX(partition_date) FROM STG_SA_AdFormatSpec)
	AND catalog_item_id IS NOT NULL
	AND afsid IS NOT NULL


