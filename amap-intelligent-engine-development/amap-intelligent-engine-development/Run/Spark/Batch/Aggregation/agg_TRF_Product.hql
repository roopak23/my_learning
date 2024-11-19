SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_Product PARTITION (partition_date = {{ params.ENDDATE }})
SELECT a.catalog_item_id
	,b.ad_format_id
	,b.breadcrumb
	,a.commercial_audience as audience_list
	,a.objective as objective_list
	,c.price_per_unit as unit_price
	,a.media_type
	,e.size
	,c.unit_of_measure as metric
	,a.adserver_id
FROM STG_sa_catalogitem a 
INNER JOIN STG_sa_adformatspec b on a.catalog_item_id = b.catalog_item_id
	AND a.partition_date = b.partition_date 
INNER JOIN STG_SA_Price_Item c on a.catalog_item_id = c.catalog_item_id 
	AND a.partition_date = c.partition_date
INNER JOIN STG_SA_AFSAdSlot d on d.afsid = b.afsid 
	AND d.partition_date = b.partition_date
INNER JOIN STG_SA_Ad_Slot e on e.sa_adslot_id = d.sa_adslot_id 
	AND e.partition_date = d.partition_date
WHERE a.partition_date = {{ params.ENDDATE }};