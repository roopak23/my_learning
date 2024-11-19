CREATE TABLE IF NOT EXISTS `TRF_Market_Order_Line_Details` (
`market_order_line_details_id` STRING,
`name` STRING,
`ad_server_name` STRING,
`ad_server_type` STRING,
`breadcrumb` STRING,
`campaign_objective` STRING,
`commercial_audience` STRING,
`day_part` STRING,
`discount_ds` DOUBLE,
`discount_ssp` DOUBLE,
`end_date` DATE,
`format` STRING,
`format_name` STRING,
`length` STRING,
`market_order_id` STRING,
`market_order_line` STRING,
`market_product_type` STRING,
`mediatype` STRING,
`advertiser_id` STRING,
`advertiser_name` STRING,
`industry` STRING,
`priceitem` STRING,
`quantity` DOUBLE,
`start_date` DATE,
`unit_net_price` DOUBLE,
`unit_price` DOUBLE,
`total_net_price` DOUBLE,
`unit_of_measure` STRING,
`frequency_capping` STRING,
`frequency_capping_quantity` INT,
`status` STRING,
`total_price` DOUBLE,
`carrier_targeting` STRING,
`custom_targeting` STRING,
`daypart_targeting` STRING,
`device_targeting` STRING,
`geo_targeting` STRING,
`os_targeting` STRING,
`time_slot_targeting` STRING,
`weekpart_targeting` STRING,
`recent_view` DATE,
`recent_change` DATE,
`gads_bidding_strategy` STRING,
`brand_id` STRING,
`brand_name` STRING
)
PARTITIONED BY (partition_date INT)
-- CLUSTERED BY (mediatype) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Market_Order_Line_Details'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `TRF_Market_Order_Line_Details`;