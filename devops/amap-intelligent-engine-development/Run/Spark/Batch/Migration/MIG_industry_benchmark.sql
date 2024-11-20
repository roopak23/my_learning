SELECT 
    `id`,
    `industry_name`,
    `system_id`,
    `system_name`,
    `cpm`,
    `cpc`,
    `ctr`
FROM stg_industry_benchmark
WHERE partition_date = {{ params.ENDDATE }}