CREATE TABLE IF NOT EXISTS `STG_SA_AFSAdSlot` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `id` STRING,
    `afsid` STRING,
    `sa_adslot_id` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (sa_adslot_id) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_AFSAdSlot'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_SA_AFSAdSlot`;