CREATE TABLE IF NOT EXISTS `STG_SA_Brand` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `brand_name` STRING,
    `account_id` STRING,
    `brand_id` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (brand_name) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_Brand'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_SA_Brand`;