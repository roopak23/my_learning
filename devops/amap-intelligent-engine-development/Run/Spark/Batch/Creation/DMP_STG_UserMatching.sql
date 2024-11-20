CREATE TABLE IF NOT EXISTS `STG_DMP_UserMatching` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `userid` STRING,
    `dmp_userid` STRING,
    `adserver_userid` STRING,
    `firstparty_userid` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (firstparty_userid) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_DMP_UserMatching'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_DMP_UserMatching`;

