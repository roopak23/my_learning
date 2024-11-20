CREATE TABLE IF NOT EXISTS `TRF_Segments` (
    `date` DATE,
    `dmp_segment_id` STRING,
    `segment_name` STRING,
    `population` INT,
    `pageviews` INT,
    `category` STRING,
    `sub_category` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (category) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Segments'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_Segments`;