INSERT OVERWRITE TABLE TRF_Frequency_Capping partition(partition_date = {{ params.ENDDATE }})
Select
	a.adserver_adslot_id,
	regexp_extract(b.parentpath , '> (.+)', 1) AS adserver_adslot_name,
	a.time_unit,
	a.num_time_units,
	a.max_impressions,
	a.factor
From STG_Frequency_Capping a
LEFT JOIN TRF_sa_ad_slot b ON a.adserver_adslot_id = b.adserver_adslotid
AND a.partition_date = b.partition_date
Where a.partition_date = {{ params.ENDDATE }} AND b.partition_date = {{ params.ENDDATE }}