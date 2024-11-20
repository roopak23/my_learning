CREATE TABLE IF NOT EXISTS `STG_SA_Ad_Ops_System` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `adserver_id` STRING,
    `adserver_name` STRING,
    `adserver_type` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (adserver_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_Ad_Ops_System'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_SA_Ad_Ops_System`;