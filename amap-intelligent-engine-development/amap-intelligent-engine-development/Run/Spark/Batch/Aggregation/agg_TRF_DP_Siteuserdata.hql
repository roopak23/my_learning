SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_DP_Siteuserdata PARTITION (partition_date = {{ params.ENDDATE }})
SELECT
    sys_datasource,
    sys_load_id,
    sys_created_on,
    dp_userid,
    url,
    ipaddress,
    browser,
    device,
    operatingsystem,
    geodatadisplay,
    start_date,
    end_date,
    REPLACE(REPLACE(category, " ", ""), "_", "") AS category,
    REPLACE(REPLACE(sub_category, " ", ""), "_", "") AS sub_category
FROM STG_DP_Siteuserdata
WHERE partition_date = {{ params.ENDDATE }};
