CREATE TABLE IF NOT EXISTS `AUD_STG_UserMatching` (
    `userid` STRING,
    `dmp_userid` STRING,
    `adserver_userid` STRING,
    `firstparty_userid` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (userid) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/AUD_STG_UserMatching'
TBLPROPERTIES("transactional"="true");

msck repair table `AUD_STG_UserMatching`;

