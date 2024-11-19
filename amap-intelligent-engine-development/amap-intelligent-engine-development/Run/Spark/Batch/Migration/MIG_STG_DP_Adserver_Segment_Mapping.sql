SELECT 
    `segment_id`,
    `segment_name`,
    `techincal_remote_id`,
    `techincal_remote_name`,
    `adserver_id`
FROM STG_DP_Adserver_Segment_Mapping
WHERE partition_date = {{ params.ENDDATE }}