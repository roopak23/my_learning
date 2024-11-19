SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_InvFuture_Commercials PARTITION (partition_date = {{ params.ENDDATE }})
SELECT 
	a.`date` AS `date`,
	a.adserver_adslot_id AS adserver_adslot_id,	
	a.adserver_adslot_name AS adserver_adslot_name,
	d.catalog_item_id AS catalog_item_id,
	SUM(a.available) AS available,
	a.adserver_id AS adserver_id,
	coalesce(a.metric,'') AS metric
FROM STG_ADSERVER_INVFUTURE A
INNER JOIN STG_SA_AD_SLOT B ON a.adserver_id = b.adserver_id
	AND a.adserver_adslot_id = b.adserver_adslotid
INNER JOIN STG_SA_AFSADSLOT C ON b.sa_adslot_id = c.sa_adslot_id
INNER JOIN STG_SA_ADFORMATSPEC D ON d.afsid= c.afsid
WHERE a.partition_date = {{ params.ENDDATE }} 
	AND b.partition_date = {{ params.ENDDATE }}
	AND c.partition_date = {{ params.ENDDATE }}
	AND d.partition_date = {{ params.ENDDATE }}
GROUP BY a.`date`, a.adserver_adslot_id, a.adserver_adslot_name, d.catalog_item_id, a.adserver_id, a.metric ;