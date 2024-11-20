CREATE TABLE if not exists `STG_DP_Adserver_Segment_Mapping` (
  `segment_id` varchar(255) NOT NULL,
  `segment_name` varchar(255),
  `technical_remote_id` varchar(255) NOT NULL,
  `technical_remote_name` varchar(255),
  `adserver_id` varchar(255) NOT NULL,
  primary key(segment_id, technical_remote_id, adserver_id)
) ;