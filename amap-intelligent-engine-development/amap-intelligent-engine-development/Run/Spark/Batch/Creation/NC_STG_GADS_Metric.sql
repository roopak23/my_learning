CREATE TABLE IF NOT EXISTS `STG_NC_GADS_Metric` (
	`sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
	`gads_id` STRING,
	`gads_name` STRING,
	`gads_total_ubs` INT,
	`adserver_id` STRING
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_NC_GADS_Metric'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `STG_NC_GADS_Metric`;