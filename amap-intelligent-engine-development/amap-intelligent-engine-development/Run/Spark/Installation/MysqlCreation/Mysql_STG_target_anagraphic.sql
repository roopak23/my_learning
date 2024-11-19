CREATE TABLE if not exists `STG_target_anagraphic` (
  `target_id` varchar(100),
  `target_name` varchar(100),
  `target_type` varchar(100),
  `adserver_target_type` varchar(100),
  `adserver_target_remote_id` varchar(100),
  `adserver_target_remote_name` varchar(100),
  `size` INT DEFAULT NULL,
  `adserver_id` varchar(100),
  primary key(target_id, target_type, adserver_target_remote_id, adserver_id)
) ;