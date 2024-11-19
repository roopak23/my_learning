SELECT 
	ROW_NUMBER() OVER (ORDER BY event_key, event_value) AS row_number,
	event_key,
	event_value
FROM stg_master_event