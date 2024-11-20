CREATE TABLE IF NOT EXISTS `trf_targeting_update` (
  `adserver_target_type` varchar(255) DEFAULT NULL, 
  `adserver_target_remote_id` varchar(255) NOT NULL,
  `adserver_target_name` varchar(255) DEFAULT NULL,
  `adserver_id` varchar(255) NOT NULL,
  primary key(adserver_target_remote_id,adserver_id)
) ;