SELECT 
	D.adserver_id,
	A.name, 
	A.display_name, 
	A.catalog_full_path,
	D.adserver_adslotid, 
	D.remote_name
from STG_SA_CatalogItem A
JOIN STG_SA_AdFormatSpec B ON A.catalog_item_id = B.catalog_item_id 
JOIN STG_SA_AFSAdSlot C ON C.afsid = B.afsid 
JOIN TRF_SA_Ad_Slot D ON D.sa_adslot_id = C.sa_adslot_id
WHERE A.partition_date =(SELECT MAX(partition_date) FROM STG_SA_CatalogItem) AND B.partition_date = (SELECT MAX(partition_date) FROM STG_SA_AdFormatSpec) AND C.partition_date = (SELECT MAX(partition_date) FROM STG_SA_AFSAdSlot) AND D.partition_date = (SELECT MAX(partition_date) FROM TRF_SA_Ad_Slot)


