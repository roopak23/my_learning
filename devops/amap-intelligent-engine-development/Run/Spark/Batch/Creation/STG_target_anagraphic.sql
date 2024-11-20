CREATE TABLE IF NOT EXISTS `STG_target_anagraphic` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `target_id` STRING,
    `target_name` STRING,
    `target_type` STRING,
    `adserver_target_type` STRING,
    `adserver_target_remote_id` STRING,
    `adserver_target_remote_name` STRING,
    `size` INT,
    `adserver_id` STRING
    )
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_target_anagraphic'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_target_anagraphic`;