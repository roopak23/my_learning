CREATE TABLE IF NOT EXISTS `AUD_MODEL_SocioDemo` (
    `userid` STRING,
    `age` STRING,
    `gender` STRING,
    `accuracy_age` FLOAT,
    `accuracy_gender` FLOAT
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (gender) INTO 2 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/AUD_MODEL_SocioDemo'
TBLPROPERTIES("transactional"="true");

msck repair table `AUD_MODEL_SocioDemo`;

