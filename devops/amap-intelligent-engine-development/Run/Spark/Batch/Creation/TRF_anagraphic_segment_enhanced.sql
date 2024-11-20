CREATE TABLE IF NOT EXISTS `TRF_anagraphic_segment_enhanced` (
	`tech_id` STRING,
	`platform` STRING,
	`platform_segment_unique_id` STRING,
	`platform_segment_name` STRING,
	`action` STRING,
	`segment_type` STRING,
	`taxonomy_segment_type` STRING,
	`taxonomy_segment_name` STRING,
	`news_connect_id` STRING
)
PARTITIONED BY (partition_date INT)
-- CLUSTERED BY (status) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_anagraphic_segment_enhanced'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_anagraphic_segment_enhanced`;