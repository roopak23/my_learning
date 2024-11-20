CREATE TABLE IF NOT EXISTS `STG_SA_Adslot_Hierarchy` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `id` STRING,
    `name` STRING,
    `adserver_id` STRING,
    `adserver_adslot_child_id` STRING,
    `adserver_adslot_parent_id` STRING,
    `adslot_child_id` STRING,
    `adslot_parent_id` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (record_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_Adslot_Hierarchy'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_SA_Adslot_Hierarchy`;