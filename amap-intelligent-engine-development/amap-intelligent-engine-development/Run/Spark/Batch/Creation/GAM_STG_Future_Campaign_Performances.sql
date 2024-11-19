CREATE TABLE IF NOT EXISTS `STG_GAM_Future_Campaign_Performances` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `remote_id` STRING,
    `order_remote_id` STRING,
    `unit_type` STRING,
    `predicted_units` INT,
    `quantity_delivered` INT,
    `matched_units` INT
    )
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_GAM_Future_Campaign_Performances'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_GAM_Future_Campaign_Performances`;