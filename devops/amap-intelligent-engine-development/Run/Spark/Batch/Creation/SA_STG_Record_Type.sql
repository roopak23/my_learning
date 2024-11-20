CREATE TABLE IF NOT EXISTS `STG_SA_Record_Type` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `record_id` STRING,
    `record_name` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (record_name) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_Record_Type'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_SA_Record_Type`;