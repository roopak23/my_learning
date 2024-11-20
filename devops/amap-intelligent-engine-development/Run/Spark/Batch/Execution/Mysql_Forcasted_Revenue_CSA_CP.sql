TRUNCATE TABLE FR_csa_cp_distribution;

INSERT INTO FR_csa_cp_distribution 	
SELECT `month`, 
common_sales_area, 
content_partner, 
platform_name, 
catalog_item_name, 
catalog_full_path, 
ROUND(SUM(monthly_booking),2) AS booking_distribution FROM (
Select 
	B.`month`,
	A.common_sales_area,
	A.content_partner,
	A.platform_name,
	B.catalog_item_name,
	B.catalog_full_path,
	B.adserver_adslot_id,
	B.adserver_adslot_name,
	B.monthly_booking 
	from FR_monthy_distribution B LEFT JOIN (SELECT common_sales_area, content_partner, platform_name,
    COALESCE(
        NULLIF(TRIM(adserver_adslot_id_5), 'NULL'),
        NULLIF(TRIM(adserver_adslot_id_4), 'NULL'),
        NULLIF(TRIM(adserver_adslot_id_3), 'NULL'),
        NULLIF(TRIM(adserver_adslot_id_2), 'NULL'),
        NULLIF(TRIM(adserver_adslot_id_1), 'NULL')
    ) AS leaf_level_adslot_id
FROM
    STG_SA_CP_CSA_AdunitMapping)A 
ON  B.adserver_adslot_id = A.leaf_level_adslot_id) A 
group by `month`,  common_sales_area ,content_partner , platform_name, catalog_item_name ;