CREATE TABLE IF NOT EXISTS `STG_FB_Future_Campaign_Performances` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `adset_id` STRING,
    `spend` DOUBLE,
    `reach` DOUBLE,
    `impressions` DOUBLE,
    `actions` DOUBLE
    )
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_FB_Future_Campaign_Performances'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_FB_Future_Campaign_Performances`;