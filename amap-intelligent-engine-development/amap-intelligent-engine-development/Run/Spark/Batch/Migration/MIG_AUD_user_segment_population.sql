SELECT 
    partition_date,
    segment_id,
    count(userid)
FROM trg_user_segment_mapping
WHERE partition_date = {{ params.ENDDATE }}
GROUP BY partition_date, segment_id
