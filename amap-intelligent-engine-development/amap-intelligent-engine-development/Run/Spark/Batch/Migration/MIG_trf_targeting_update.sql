SELECT 
    `adserver_target_type`,
    `adserver_target_remote_id`,
    `adserver_target_name`,
    `adserver_id`
FROM trf_targeting_update
WHERE partition_date = (SELECT MAX(partition_date) FROM trf_targeting_update)