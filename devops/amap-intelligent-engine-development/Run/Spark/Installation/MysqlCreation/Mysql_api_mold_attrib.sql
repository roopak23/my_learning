CREATE TABLE IF NOT EXISTS `api_mold_attrib` (
  `market_order_id` varchar(255) NOT NULL,
  `market_order_line_details_id` varchar(255) NOT NULL,
  `attrib_type` varchar(255) NOT NULL,
  `attrib_value` varchar(255) NOT NULL,
  `create_date` datetime NOT NULL,
  `update_date` datetime DEFAULT NULL,
  PRIMARY KEY (`market_order_id`,`market_order_line_details_id`,`attrib_type`,`attrib_value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;


SELECT if (
    exists(
      select distinct index_name
      from information_schema.statistics
      where table_schema = 'data_activation'
        and table_name = 'api_mold_attrib'
        and index_name = 'api_mold_attrib_I1'
    ),
    'select ''index api_mold_attrib_I1 exists'' _______;',
    'create index api_mold_attrib_I1 on data_activation.api_mold_attrib(market_order_line_details_id)'
  ) into @a;
PREPARE stmt1
FROM @a;
EXECUTE stmt1;
DEALLOCATE PREPARE stmt1;