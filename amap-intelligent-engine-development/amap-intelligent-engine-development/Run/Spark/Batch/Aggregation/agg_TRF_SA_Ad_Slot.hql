INSERT OVERWRITE TABLE TRF_SA_Ad_Slot partition(partition_date = {{ params.ENDDATE }})
SELECT  s.sys_datasource,
        s.sys_load_id,
        s.sys_created_on,
        s.sa_adslot_id,
        s.name,
        s.status,
        s.size,
        s.type,
        s.adserver_adslotid,
        s.adserver_id,
        s.publisher, 
        s.remote_name, 
        s.device ,
        s.ParentPath
 FROM STG_SA_AD_SLOT s 
 LEFT JOIN TRF_Master_AdSlotSkip skip
	   ON s.adserver_adslotid = skip.adserver_adslot_id
WHERE s.partition_date = {{ params.ENDDATE }}
  AND skip.adserver_adslot_id IS NULL