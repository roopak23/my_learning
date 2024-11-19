CREATE TABLE IF NOT EXISTS `STG_DP_Useranagraphic` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `dp_userid` STRING,
    `attribute_name` STRING,
	`attribute_value` STRING
    )
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_DP_Useranagraphic'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_DP_Useranagraphic`;