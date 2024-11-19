
INSERT OVERWRITE TABLE TRF_DTF_Additional_Dimensions partition (partition_date = {{ params.ENDDATE }})	
SELECT  dtf.`date`,
		dtf.adserver_id,
		dtf.adserver_adslot_id,
		dtf.adserver_adslot_name,
		dtf.advertiser_id,
		dtf.remote_id,
		dtf.country,
		dtf.State,
		dtf.city,
		dtf.platform_name,
		sum(dtf.impressions) impressions,
		dtf.event,
		dtf.pod_position,
		dtf.video_position,
		dtf.audience_name,
		dtf.selling_type 
FROM (
	 SELECT dtf.`date`,
			dtf.adserver_id,
			coalesce(smar.new_adserver_adslot_id,dtf.adserver_adslot_id) adserver_adslot_id,
			dtf.adserver_adslot_name,
			dtf.advertiser_id,
			dtf.remote_id,
			dtf.country,
			dtf.State,
			dtf.city,
			dtf.platform_name,
			dtf.impressions,
			dtf.event,
			dtf.pod_position,
			dtf.video_position,
			dtf.audience_name,
			dtf.selling_type 
		FROM TRF_DTF_Additional_Dimensions_Pre  dtf
		LEFT JOIN STG_Master_AdSlotRemap smar
			ON dtf.adserver_adslot_id = smar.old_adserver_adslot_id
		WHERE partition_date = {{ params.ENDDATE }} 
	 ) dtf
LEFT JOIN TRF_Master_AdSlotSkip skip
	   ON dtf.adserver_adslot_id = skip.adserver_adslot_id
WHERE skip.adserver_adslot_id IS NULL
GROUP BY dtf.`date`,
		dtf.adserver_id,
		dtf.adserver_adslot_id,
		dtf.adserver_adslot_name,
		dtf.advertiser_id,
		dtf.remote_id,
		dtf.country,
		dtf.State,
		dtf.city,
		dtf.platform_name,
		dtf.event,
		dtf.pod_position,
		dtf.video_position,
		dtf.audience_name,
		dtf.selling_type 
