SELECT 
	`date`, 
	adserver_id, 
	adserver_adslot_id, 
	adserver_adslot_name, 
	platform_name, 
	state, 
	city, 
	event, 
	pod_position, 
	video_position, 
	metric, 
	future_capacity
FROM default.ml_invforecastingoutputsegmentdistributed
WHERE partition_date = {{ params.ENDDATE }}
