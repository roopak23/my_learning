CREATE TABLE IF NOT EXISTS `STG_SA_Tech_Line_Targeting` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `tech_line_id` STRING,
    `adserver_target_remote_id` STRING,
    `adserver_target_name` STRING
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_Tech_Line_Targeting'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `STG_SA_Tech_Line_Targeting`;