CREATE TABLE if not exists `api_segment_reach` (
  `adserver_id` varchar(255) NOT NULL, 
  `commercial_audience_name` varchar(255) NOT NULL,
  `adserver_target_remote_id` varchar(255) NOT NULL,
  `adserver_target_name` varchar(255) DEFAULT NULL,
  `reach` int DEFAULT NULL,
  `impression` int DEFAULT NULL,
  `spend` Double DEFAULT NULL,
  primary key(adserver_id,commercial_audience_name,adserver_target_remote_id)
) ;