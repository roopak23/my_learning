SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_Inventory_Check PARTITION (partition_date = {{ params.ENDDATE }})
SELECT a.`date`
	,a.adserver_id as system_id
	,a.adserver_adslot_id as remote_id
	,c.ad_format_id
	,c.breadcrumb
	,a.future_capacity
	,(a.future_capacity-(a.booked+a.reserved)) as availability
	,a.adserver_target_name as audience
	,a.adserver_target_remote_id as audience_id
	,d.unit_of_measure as metric
FROM SO_Inventory a 
INNER JOIN STG_SA_CatalogItem b on a.catalog_item_id = b.catalog_item_id
	AND a.partition_date = b.partition_date 
INNER JOIN STG_SA_AdFormatSpec c on b.catalog_item_id = c.catalog_item_id 
	AND b.partition_date = c.partition_date
INNER JOIN STG_SA_Price_Item d on b.catalog_item_id = d.catalog_item_id 
	AND b.partition_date = d.partition_date
WHERE a.partition_date = {{ params.ENDDATE }};