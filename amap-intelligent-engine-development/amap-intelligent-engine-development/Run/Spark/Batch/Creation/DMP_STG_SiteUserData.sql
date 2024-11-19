CREATE TABLE IF NOT EXISTS `STG_DMP_SiteUserdata` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,    
    `url_timestamp` BIGINT,
    `url_day` DATE,
    `krux_userid` STRING,
    `ipaddress` STRING,
    `browser` STRING,
    `device` STRING,
    `operatingsystem` STRING,
    `url` STRING,
    `sitedata` STRING,
    `geodatadisplay` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (operatingsystem) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_DMP_SiteUserdata'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_DMP_SiteUserdata`;