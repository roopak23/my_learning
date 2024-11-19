TRUNCATE TABLE CatalogItem_Adsots_Hierarchy;

CREATE TEMPORARY TABLE Temp_Ad_Slot_Hierarchy AS
WITH RECURSIVE Ad_slot_hierarchy (
	adserver_id, 
	adserver_adslot_id,
	adserver_adslot_parent_id,
	catalog_item_name,
	catalog_full_path) AS 
    (
    SELECT 
        aah.adserver_id, 
        aah.adserver_adslot_id, 
        aah.adserver_adslot_parent_id,
        cam.catalog_item_name, 
        cam.catalog_full_path
    FROM 
        api_adslot_hierarchy aah
    INNER JOIN 
        CatalogItem_Adsots_Mapping cam ON aah.adserver_adslot_parent_id = cam.adserver_adslot_id
        AND aah.adserver_id = cam.adserver_id

    UNION ALL

    SELECT 
        a.adserver_id, 
        a.adserver_adslot_id, 
        a.adserver_adslot_parent_id,
        ah.catalog_item_name, 
        ah.catalog_full_path
    FROM 
        api_adslot_hierarchy a
    JOIN 
        Ad_slot_hierarchy ah ON a.adserver_adslot_parent_id = ah.adserver_adslot_id
        AND a.adserver_id = ah.adserver_id
)
SELECT * FROM Ad_slot_hierarchy;

INSERT INTO CatalogItem_Adsots_Hierarchy (
    adserver_id, 
    catalog_item_name, 
    catalog_full_path, 
    adserver_adslot_id, 
    adserver_adslot_name
)
SELECT
    a.adserver_id, 
    a.catalog_item_name, 
    a.catalog_full_path,
    a.adserver_adslot_id,
    b.remote_name
FROM 
    Temp_Ad_Slot_Hierarchy a
INNER JOIN 
    STG_SA_Ad_Slot b ON a.adserver_adslot_id = b.adserver_adslot_id
    AND a.adserver_id = b.adserver_id;
	

INSERT INTO CatalogItem_Adsots_Hierarchy (
    adserver_id, 
    catalog_item_name, 
    catalog_full_path, 
    adserver_adslot_id, 
    adserver_adslot_name
)
SELECT 
    c.adserver_id, 
    c.catalog_item_name, 
    c.catalog_full_path,
    c.adserver_adslot_id,
    c.adserver_adslot_name
FROM 
    CatalogItem_Adsots_Mapping c
LEFT JOIN (
    SELECT DISTINCT 
        a.catalog_item_name
    FROM 
        Temp_Ad_Slot_Hierarchy a
    INNER JOIN 
        STG_SA_Ad_Slot b ON a.adserver_adslot_id = b.adserver_adslot_id
    AND a.adserver_id = b.adserver_id
) AS ValidItems ON c.catalog_item_name = ValidItems.catalog_item_name;


DROP TEMPORARY TABLE IF EXISTS Temp_Ad_Slot_Hierarchy;
