DELETE FROM default.stg_sa_targeting WHERE
    partition_date = {{ params.ENDDATE }} AND
    sys_datasource ='STG_SA_Targeting_insert' AND
    target_id = 'all' AND
    adserver_target_type = 'audience' AND
    adserver_target_remote_id = 'all' AND
    adserver_target_name = 'audience';

-----------------------------------------------

INSERT INTO default.stg_sa_targeting (
    sys_datasource,
    sys_load_id,
    sys_created_on,
    target_id,
    adserver_target_type,
    adserver_target_remote_id,
    adserver_target_name,
    adserver_id,
    adserver_target_category,
    adserver_target_code,
    partition_date
    )
SELECT
    'STG_SA_Targeting_insert' AS sys_datasource,
    from_unixtime(unix_timestamp(), 'yyyyMMddHHmmssSSS') AS sys_load_id,
    from_unixtime(unix_timestamp(), 'yyyy-MM-dd HH:mm:ss.SSS') AS sys_created_on,
    'all' AS target_id,
    'audience' AS adserver_target_type,
    'all' AS adserver_target_remote_id,
    'audience' AS adserver_target_name,
    a.adserver_id,
    NULL AS adserver_target_category,
    NULL AS adserver_target_code,
    a.partition_date
FROM
    (
    SELECT DISTINCT adserver_id, partition_date -- Fetch only unique adserver ids in daily data batch.
    FROM default.stg_sa_targeting
    WHERE partition_date = {{ params.ENDDATE }}
    AND adserver_id IS NOT NULL
    ) a;