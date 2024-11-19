SELECT 
    `commercial_audience_id`,
    `commercial_audience_name`
FROM STG_audience_anagraphic
WHERE partition_date = {{ params.ENDDATE }}