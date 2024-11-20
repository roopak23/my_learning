CREATE TABLE if not exists `STG_taxonomy` (
  `commercial_audience_id` varchar(255),
  `target_id` varchar(255),
  primary key(commercial_audience_id, target_id)
) ;