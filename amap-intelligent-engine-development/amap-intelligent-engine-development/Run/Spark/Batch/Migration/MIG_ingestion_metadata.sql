SELECT
    `load_id` ,
    `datasource` ,
    `table_name` ,
    `total_rows` ,
    `non_valid_rejected` ,
    `mandatory_rejected`,
    `duplicates_rejected` ,
    `dq_rejected` ,
    `rows_loaded` ,
    `partition_date`
 FROM ingestion_metadata
 WHERE partition_date = {{ params.ENDDATE }}



