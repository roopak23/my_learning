SELECT 
    `price_item_id`,
    `catalog_item_id`,
    `currency`,
    `commercial_audience`,
    `price_list`,
    `price_per_unit`,
    `spot_length`,
    `unit_of_measure`,
    `sys_datasource`
FROM STG_SA_Price_Item
WHERE partition_date = (SELECT MAX(partition_date) FROM STG_SA_Price_Item)
