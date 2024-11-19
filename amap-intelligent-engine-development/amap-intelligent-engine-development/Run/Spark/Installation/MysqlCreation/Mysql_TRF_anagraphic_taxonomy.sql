CREATE TABLE IF NOT EXISTS  `TRF_anagraphic_taxonomy` (
  `tech_id` varchar(255) NOT NULL,
  `taxonomy_segment_name` varchar(255) NOT NULL,
  `taxonomy_segment_type` varchar(255) NOT NULL,
  `newsconnect_segment_size` INT,
  PRIMARY KEY (`tech_id`)
);