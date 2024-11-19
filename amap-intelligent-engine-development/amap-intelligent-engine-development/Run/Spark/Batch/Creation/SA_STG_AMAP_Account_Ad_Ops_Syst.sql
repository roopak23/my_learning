CREATE TABLE IF NOT EXISTS `STG_SA_AMAP_Account_Ad_Ops_Syst` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `adserver_id` STRING,
    `account_id` STRING,
    `ad_ops_system` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (ad_ops_system) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_AMAP_Account_Ad_Ops_Syst'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_SA_AMAP_Account_Ad_Ops_Syst`;