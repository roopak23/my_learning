SELECT 
    `commercial_audience_id`,
    `target_id`
FROM STG_taxonomy
WHERE partition_date = (SELECT MAX(partition_date) FROM STG_taxonomy)