CREATE TABLE IF NOT EXISTS `STG_CDP_attribute` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `target_id` STRING,
    `attribute_name` STRING,
    `attribute_value` STRING
    )
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_CDP_attribute'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_CDP_attribute`;