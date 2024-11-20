CREATE TABLE IF NOT EXISTS `TRF_Campaign` (
`advertiser_id` STRING ,
`tech_line_id` STRING ,
`tech_order_id` STRING ,
`tech_line_name` STRING ,
`market_order_id` STRING ,
`market_order_line_details_id` STRING ,
`system_id` STRING ,
`remote_id` STRING ,
`remote_name` STRING ,
`start_date` DATE ,
`end_date` DATE ,
`duration` INT ,
`unit_net_price` DOUBLE ,
`discount_ds` DOUBLE ,
`discount_ssp` DOUBLE ,
`budget` DOUBLE ,
`metric` STRING ,
`target_quantity` INT ,
`mediatype` STRING ,
`delivery_rate_type` STRING ,
`objective` STRING ,
`ad_format_id` STRING ,
`commercial_audience` STRING ,
`carrier_targeting` STRING ,
`custom_targeting` STRING ,
`daypart_targeting` STRING ,
`device_targeting` STRING ,
`geo_targeting` STRING ,
`os_targeting` STRING ,
`time_slot_targeting` STRING ,
`weekpart_targeting` STRING,
`creative_ad_type` STRING,
`creative_size` STRING,
`priority` INT,
`line_type` STRING,
`frequency_capping` STRING,
`frequency_capping_quantity` INT,
`unit_price` DOUBLE,
`adserver_target_remote_id` STRING,
`adserver_target_name` STRING,
`adserver_target_type` STRING,
`adserver_target_category` STRING,
`industry` STRING,
`audience_name` STRING,
`frequency_cap` STRING
)

PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Campaign'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `TRF_Campaign`;