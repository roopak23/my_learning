SELECT 
    `target_id`,
    `attribute_name`,
    `attribute_value`
FROM STG_CDP_attribute
WHERE partition_date = {{ params.ENDDATE }}