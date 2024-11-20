-- data_activation.DataMart_Inventory source

CREATE OR REPLACE
ALGORITHM = UNDEFINED VIEW data_activation.DataMart_Inventory AS
select
    cast(a.date as date) AS date,
    a.metric AS metric,
    a.adserver_adslot_id AS adserver_adslot_id,
    a.adserver_adslot_name AS adserver_adslot_name,
    a.audience_name AS audience_name,
        SUBSTRING_INDEX(a.adserver_adslot_name, '»', 1) AS level1,
    CASE 
        WHEN LENGTH(a.adserver_adslot_name) - LENGTH(REPLACE(a.adserver_adslot_name, '»', '')) >= 1
        THEN SUBSTRING_INDEX(SUBSTRING_INDEX(a.adserver_adslot_name, '»', 2), '»', -1)
        ELSE NULL 
    END AS level2,
    CASE 
        WHEN LENGTH(a.adserver_adslot_name) - LENGTH(REPLACE(a.adserver_adslot_name, '»', '')) >= 2
        THEN SUBSTRING_INDEX(SUBSTRING_INDEX(a.adserver_adslot_name, '»', 3), '»', -1)
        ELSE NULL 
    END AS level3,
    CASE 
        WHEN LENGTH(a.adserver_adslot_name) - LENGTH(REPLACE(a.adserver_adslot_name, '»', '')) >= 3
        THEN SUBSTRING_INDEX(SUBSTRING_INDEX(a.adserver_adslot_name, '»', 4), '»', -1)
        ELSE NULL 
    END AS level4,
    CASE 
        WHEN LENGTH(a.adserver_adslot_name) - LENGTH(REPLACE(a.adserver_adslot_name, '»', '')) >= 4
        THEN SUBSTRING_INDEX(SUBSTRING_INDEX(a.adserver_adslot_name, '»', 5), '»', -1)
        ELSE NULL 
    END AS level5,
    d.catalog_item_id AS catalog_item_id,
    d.media_type AS media_type,
    d.catalog_level AS catalog_level,
    d.display_name AS L2,
    d.record_type AS record_type,
    d.parent_id AS L1Id,
    f.display_name AS L1,
    f.parent_id AS L0Id,
    m.display_name AS L0,
    a.future_capacity AS future_capacity,
    a.booked AS booked,
    a.reserved AS reserved,
	 CASE WHEN (a.booked-a.future_capacity) > 0 THEN (a.booked-a.future_capacity) ELSE 0 END as overbooked,
	a.city as city,
	a.event as event,
	a.state as state,
    a.overwriting AS overwriting,
    a.percentage_of_overwriting AS percentage_of_overwriting,
    a.overwritten_impressions AS overwritten_impressions,
    a.overwriting_reason AS overwriting_reason,
    a.use_overwrite AS use_overwrite
from
    (((data_activation.api_inventorycheck a
left join (data_activation.STG_SA_Ad_Slot e
left join (data_activation.STG_SA_AFSAdSlot b
left join (data_activation.STG_SA_AdFormatSpec c
left join data_activation.STG_SA_CatalogItem d on
    ((c.catalog_item_id = d.catalog_item_id))) on
    ((b.afsid = c.afsid))) on
    ((e.sa_adslot_id = b.sa_adslot_id))) on
    ((a.adserver_adslot_id = e.adserver_adslot_id)))
left join data_activation.STG_SA_CatalogItem f on
    ((f.catalog_item_id = d.parent_id)))
left join data_activation.STG_SA_CatalogItem m on
    ((m.catalog_item_id = f.parent_id)));
