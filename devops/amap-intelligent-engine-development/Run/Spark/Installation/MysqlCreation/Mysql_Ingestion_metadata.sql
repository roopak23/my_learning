CREATE TABLE IF NOT EXISTS ingestion_metadata(
   `load_id` BIGINT, 
  `datasource` varchar(255), 
  `table_name` varchar(255), 
  `total_rows` int, 
  `non_valid_rejected` int, 
  `mandatory_rejected` int, 
  `duplicates_rejected` int,
  `dq_rejected` int, 
  `rows_loaded` int,
  `partition_date` int
  );