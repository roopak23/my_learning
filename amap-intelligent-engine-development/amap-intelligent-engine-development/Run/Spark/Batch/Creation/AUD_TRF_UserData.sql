CREATE TABLE IF NOT EXISTS `AUD_TRF_UserData` (
    `url_timestamp` timestamp,
    `dmp_userid` STRING,
    `ipaddress` STRING,
    `browser` STRING,
    `device` STRING,
    `operatingsystem` STRING,
    `url` STRING,
    `sitedata` STRING,
    `domain` STRING,
    `country` STRING,
    `region` STRING,
    `zipcode` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (device) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/AUD_TRF_UserData'
TBLPROPERTIES("transactional"="true");

msck repair table `AUD_TRF_UserData`;

