CREATE TABLE IF NOT EXISTS `TRF_SAR_Views` (
    `date` DATE,
    `site` STRING,
    `pageviews` INT,
    `unique_pageviews` INT,
    `content_type` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (content_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_SAR_Views'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_SAR_Views`;