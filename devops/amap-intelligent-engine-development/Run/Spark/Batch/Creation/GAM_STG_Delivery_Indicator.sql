CREATE TABLE IF NOT EXISTS `STG_GAM_Delivery_Indicator` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `line_item_remote_id` STRING,
    `order_remote_id` STRING,
    `end_date` DATE,
    `delivery_rate_type` STRING,
    `line_type` STRING,
    `selling_type` STRING,
    `expected_delivery` DOUBLE,
    `actual_delivery` DOUBLE,
    `impressions_delivered` INT,
    `clicks_delivered` INT,
    `status` STRING
    )
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_GAM_Delivery_Indicator'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_GAM_Delivery_Indicator`;