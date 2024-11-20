SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_adslot_available PARTITION (partition_date = {{ params.ENDDATE }})
SELECT a.catalog_item_id
	,a.name
	,c.sa_adslot_id
	,d.type
	,d.adserver_adslotid
	,d.adserver_id
FROM STG_sa_catalogitem a 
INNER JOIN STG_sa_adformatspec b on a.catalog_item_id = b.catalog_item_id
INNER JOIN STG_sa_afsadslot c on b.afsid = c.afsid 
INNER JOIN STG_sa_ad_slot d on c.sa_adslot_id = d.sa_adslot_id
WHERE (d.status = 'Active' or d.status = 'ACTIVE' or d.status = 'active')
and a.partition_date = {{ params.ENDDATE }}
and b.partition_date = {{ params.ENDDATE }}
and c.partition_date = {{ params.ENDDATE }}
and d.partition_date = {{ params.ENDDATE }};
