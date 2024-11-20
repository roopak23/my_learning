CREATE TABLE IF NOT EXISTS `STG_SA_Account` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `account_id` STRING,
    `account_name` STRING,
    `account_type` STRING,
    `record_type` STRING,
    `industry` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (record_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_Account'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_SA_Account`;