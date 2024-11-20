CREATE TABLE IF NOT EXISTS `STG_SA_Ad_Slot` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `sa_adslot_id` STRING,
    `name` STRING,
    `status` STRING,
    `size` STRING,
    `type` STRING,
    `adserver_adslotid` STRING,
    `adserver_id` STRING,
    `publisher` string, 
    `remote_name` string, 
    `device` string,
    `ParentPath` string
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_Ad_Slot'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_SA_Ad_Slot`;
