CREATE TABLE IF NOT EXISTS `STG_taxonomy` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `commercial_audience_id` STRING,
    `target_id` STRING
    )
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_taxonomy'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_taxonomy`;