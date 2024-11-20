CREATE TABLE if not exists `TRF_anagraphic_segment_enhanced` (
  `tech_id` varchar(255), 
  `platform` varchar(255) DEFAULT NULL, 
  `platform_segment_unique_id` varchar(255) NOT NULL,
  `platform_segment_name` varchar(255) DEFAULT NULL,
  `action` varchar(255) DEFAULT NULL,
  `segment_type` varchar(255) DEFAULT NULL,
  `taxonomy_segment_type` varchar(255) DEFAULT NULL,
  `taxonomy_segment_name` varchar(255) DEFAULT NULL,
  `news_connect_id` varchar(255) DEFAULT NULL,
  primary key(tech_id)
) ;