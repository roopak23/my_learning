CREATE TABLE if not exists `STG_CDP_attribute` (
  `target_id` varchar(255),
  `attribute_name` varchar(255),
  `attribute_value` varchar(255),
  primary key(target_id)
) ;