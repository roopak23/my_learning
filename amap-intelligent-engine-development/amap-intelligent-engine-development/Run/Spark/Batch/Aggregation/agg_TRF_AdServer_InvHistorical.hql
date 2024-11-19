INSERT OVERWRITE TABLE TRF_AdServer_InvHistorical partition(partition_date = {{ params.ENDDATE }})
Select  sah.`date`,
		sah.adserver_adslot_id,
		sah.`adserver_adslot_name`,
		sum(sah.`total_code_served_count`) total_code_served_count,
		sum(sah.`unifilled_impression`) unifilled_impression,
		sum(sah.`unmatched_ad_requests`) unmatched_ad_requests,
		sah.`adserver_id`,
		sah.`metric`
FROM ( 
		SELECT  saih.`date`,
				coalesce(smar.new_adserver_adslot_id,saih.`adserver_adslot_id`) adserver_adslot_id,
				saih.`adserver_adslot_name`,
				saih.`total_code_served_count`,
				saih.`unifilled_impression`,
				saih.`unmatched_ad_requests`,
				saih.`adserver_id`,
				saih.`metric`
		   FROM STG_AdServer_InvHistorical saih
		LEFT JOIN STG_Master_AdSlotRemap smar
			ON saih.adserver_adslot_id = smar.old_adserver_adslot_id
		WHERE partition_date = {{ params.ENDDATE }}
	 ) sah 
LEFT JOIN TRF_Master_AdSlotSkip skip
	   ON sah.adserver_adslot_id = skip.adserver_adslot_id
WHERE skip.adserver_adslot_id IS NULL
GROUP BY sah.`date`,
		sah.adserver_adslot_id,
		sah.`adserver_adslot_name`,
		sah.`adserver_id`,
		sah.`metric`

