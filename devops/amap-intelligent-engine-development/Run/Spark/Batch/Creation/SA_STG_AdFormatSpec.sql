CREATE TABLE IF NOT EXISTS `STG_SA_AdFormatSpec` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `afsid` STRING,
    `ad_format_id` STRING,
    `catalog_item_id` STRING,
    `breadcrumb` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (breadcrumb) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_AdFormatSpec'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_SA_AdFormatSpec`;