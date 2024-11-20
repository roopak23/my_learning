SELECT 
    `target_id`,
    `adserver_target_type`,
    `adserver_target_remote_id`,
    `adserver_target_name`,
    coalesce(`adserver_id`,'') adserver_id,
    `adserver_target_category`,
    `adserver_target_code`,
    `sys_datasource`
FROM STG_SA_Targeting
WHERE partition_date = (SELECT MAX(partition_date) FROM STG_SA_Targeting)
