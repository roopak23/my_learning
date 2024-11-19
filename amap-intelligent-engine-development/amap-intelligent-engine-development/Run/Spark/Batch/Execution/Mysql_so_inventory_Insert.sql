REPLACE INTO data_activation.so_inventory
(`date`, adserver_adslot_id, adserver_id, metric, media_type, catalog_value,
record_type, catalog_item_id,catalog_item_name, future_capacity, booked, reserved)
SELECT 
invchk.`date`, 
invchk.adserver_adslot_id,
invchk.adserver_id,
invchk.metric,
catitem.media_type,
catitem.display_name as catalog_value, -- please confirm is alias is correct
catitem.record_type,
catitem.catalog_item_id as catalog_item_id,
catitem.name as catalog_item_name, -- please confirm is alias is correct
invchk.future_capacity, 
invchk.booked, 
invchk.reserved
FROM api_inventorycheck invchk inner join STG_SA_Ad_Slot adslot 
on invchk.adserver_adslot_id = adslot.adserver_adslot_id 
AND invchk.adserver_id = adslot.adserver_id 
inner join STG_SA_AFSAdSlot afsadslot on adslot.sa_adslot_id = afsadslot.sa_adslot_id 
inner join STG_SA_AdFormatSpec adformatspec on afsadslot.afsid = adformatspec.afsid
inner join STG_SA_CatalogItem catitem on adformatspec.catalog_item_id = catitem.catalog_item_id ;
