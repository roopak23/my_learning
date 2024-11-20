CREATE TABLE IF NOT EXISTS `API_Reserved_History` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `date` DATE,
    `market_order_line_details_name` STRING,
    `market_order_line_details_id` STRING,
    `tech_line_id` STRING,
    `tech_line_name` STRING,
    `tech_line_remote_id` STRING,    
    `start_date` DATE,
    `end_date` DATE,
    `status` STRING,    
    `media_type` STRING,
    `commercial_audience` STRING,
    `quantity` INT,
    `unit_type` STRING,
    `unit_price` DOUBLE,
    `unit_net_price` DOUBLE,
    `total_price` DOUBLE,  
    `adserver_adslot_name` STRING,
	`adserver_id` STRING,
	`adserver_adslot_id` STRING,  
    `adserver_target_remote_id` STRING,
    `adserver_target_name` STRING,
    `adserver_target_type` STRING,
    `adserver_target_category` STRING,
    `adserver_target_code` STRING,
    `length` INT,
    `format_id` STRING,
    `price_item` STRING,    
    `breadcrumb` STRING,
    `advertiser_id` STRING,
    `brand_name` STRING,    
    `market_order_id` STRING,
    `market_order_name` STRING,
    `frequency_cap` INT,
    `day_part` STRING,
    `priority` STRING,
    `ad_format_id` STRING,
    `market_product_type_id` STRING,
    `calc_type` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (media_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/API_Reserved_History'
TBLPROPERTIES("transactional"="true");

msck repair table `API_Reserved_History`;