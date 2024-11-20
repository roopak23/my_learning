SELECT DISTINCT
    adserver_adslot_id,
    adserver_adslot_name,
    UPPER(TRIM(time_unit)),
	num_time_units,
	max_impressions,
    factor
FROM TRF_Frequency_Capping
WHERE partition_date = (SELECT MAX(partition_date) FROM TRF_Frequency_Capping)