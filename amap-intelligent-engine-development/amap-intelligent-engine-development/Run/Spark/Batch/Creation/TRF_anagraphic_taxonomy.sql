CREATE TABLE IF NOT EXISTS `TRF_anagraphic_taxonomy` (
	`tech_id` STRING,
	`taxonomy_segment_name` STRING,
	`taxonomy_segment_type` STRING,
	`newsconnect_segment_size` INT
)
PARTITIONED BY (partition_date INT)
-- CLUSTERED BY (status) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_anagraphic_taxonomy'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_anagraphic_taxonomy`;