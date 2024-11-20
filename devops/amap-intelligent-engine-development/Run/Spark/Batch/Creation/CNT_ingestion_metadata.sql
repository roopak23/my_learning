-- ingestion_metadata definition

CREATE TABLE IF NOT EXISTS `ingestion_metadata`(
  `load_id` bigint, 
  `datasource` string, 
  `table_name` string, 
  `total_rows` int, 
  `non_valid_rejected` int, 
  `mandatory_rejected` int, 
  `duplicates_rejected` int,
  `dq_rejected` int,
  `rows_loaded` int)
PARTITIONED BY ( 
  `partition_date` int)

STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/ingestion_metadata'
TBLPROPERTIES("transactional"="true");

msck repair table `ingestion_metadata`;