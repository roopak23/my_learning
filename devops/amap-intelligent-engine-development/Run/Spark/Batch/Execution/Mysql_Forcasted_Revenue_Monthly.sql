TRUNCATE TABLE FR_monthy_grouping;

INSERT INTO FR_monthy_grouping 	
Select 
	A.`Month`,
	B.catalog_item_name,
	B.catalog_full_path,
	A.adserver_adslot_id,
	B.adserver_adslot_name,
	A.MonthlyGrouping
	FROM (Select 
		adserver_id,
		DATE_FORMAT(`date`, '%m/%Y') AS `Month`,
        adserver_adslot_id,
        SUM(booked + reserved ) AS MonthlyGrouping
    FROM api_inventorycheck 
    GROUP BY 
		adserver_id,
        adserver_adslot_id,
        UPPER(DATE_FORMAT(`date`, '%b'))) A
    INNER JOIN (SELECT DISTINCT
		adserver_id,
		catalog_item_name, 
		catalog_full_path, 
		adserver_adslot_id, 
		adserver_adslot_name 
		from CatalogItem_Adsots_Hierarchy) B 
    ON A.adserver_adslot_id = B.adserver_adslot_id
	AND A.adserver_id = B.adserver_id;
