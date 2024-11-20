SELECT 
    `target_id`,
    `target_name`,
    `target_type`,
    `adserver_target_type`,
    `adserver_target_remote_id`,
    `adserver_target_remote_name`,
    `size`,
    `adserver_id`
FROM STG_target_anagraphic
WHERE partition_date = (SELECT MAX(partition_date) FROM STG_target_anagraphic)