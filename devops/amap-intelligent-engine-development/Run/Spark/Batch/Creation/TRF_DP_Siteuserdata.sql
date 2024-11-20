CREATE TABLE IF NOT EXISTS `TRF_DP_Siteuserdata` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,    
    `dp_userid` STRING,
    `url` STRING,
    `ipaddress` STRING,
    `browser` STRING,
    `device` STRING,
    `operatingsystem` STRING,
    `geodatadisplay` STRING,
	`start_date` TIMESTAMP,
	`end_date` TIMESTAMP,
	`category` STRING,
	`sub_category` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (operatingsystem) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_DP_Siteuserdata'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_DP_Siteuserdata`;