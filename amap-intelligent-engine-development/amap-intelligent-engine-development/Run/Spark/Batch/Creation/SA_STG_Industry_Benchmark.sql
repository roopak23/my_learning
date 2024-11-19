CREATE TABLE IF NOT EXISTS `STG_SA_Industry_Benchmark` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `id` STRING,
    `industry_name` STRING,
    `system_id` STRING,
    `system_name` STRING,
    `cpm` Double,
    `cpc` Double,
    `ctr` Double
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_Industry_Benchmark'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_SA_Industry_Benchmark`;