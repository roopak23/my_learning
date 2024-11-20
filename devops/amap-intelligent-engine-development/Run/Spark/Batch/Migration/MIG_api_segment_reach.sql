SELECT 
    coalesce(`adserver_id`,'') adserver_id,
	trim(`commercial_audience_name`) commercial_audience_name,
    `adserver_target_remote_id`,
    `adserver_target_name`,
    `reach`,
    `impression`,
    `spend`
FROM api_segment_reach
WHERE partition_date = (SELECT MAX(partition_date) FROM api_segment_reach)



