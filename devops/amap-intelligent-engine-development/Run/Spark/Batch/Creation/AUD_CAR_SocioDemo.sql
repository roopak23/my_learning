CREATE TABLE IF NOT EXISTS `CAR_SocioDemo` (
    `userid` STRING,
    `age` STRING,
    `gender` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (gender) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/CAR_SocioDemo'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `CAR_SocioDemo`;
