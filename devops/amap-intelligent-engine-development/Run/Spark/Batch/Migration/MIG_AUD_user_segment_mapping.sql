SELECT
    userid,
    segment_id
 FROM trg_user_segment_mapping
 WHERE partition_date = {{ params.ENDDATE }}
