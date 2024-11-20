CREATE TABLE IF NOT EXISTS `LAL_SocioDemo` (
    `userid` STRING,
    `age` STRING,
    `gender` STRING,
	`accuracy_age` FLOAT,
    `accuracy_gender` FLOAT
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (gender) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/LAL_SocioDemo'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `LAL_SocioDemo`;
