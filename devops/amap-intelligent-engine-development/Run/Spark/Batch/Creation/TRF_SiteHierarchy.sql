CREATE TABLE IF NOT EXISTS `TRF_SiteHierarchy` (
    `dmp_userid` STRING,
    `url_day` STRING,
    `site` STRING,
    `section` STRING,
    `subsection_1id` STRING,
    `subsection_2id` STRING,
    `subsection_3id` STRING,
    `subsection_4id` STRING,
    `sitepage` STRING,
    `publisher_userid` STRING,
    `dmp_segment_id` STRING,
    `segment_name` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (segment_name) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_SiteHierarchy'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_SiteHierarchy`;