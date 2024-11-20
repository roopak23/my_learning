CREATE TABLE IF NOT EXISTS `STG_SA_Market_Order` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `market_order_id` STRING,
    `brand_name` STRING,
    `brand_id` STRING,
    `market_order_name` STRING,
    `campaign_name` STRING,
    `agency` STRING,
    `advertiser_id` STRING,
    `advertiser_name` STRING,
    `campaign_objective` STRING,
    `campaign_status` STRING,
    `start_date` BIGINT,
    `end_date` BIGINT,
    `commercial_audience` STRING,
    `total_net_price` DOUBLE,
    `total_price` DOUBLE,
    `recent_view` BIGINT,
    `recent_change` BIGINT,
    `tag` STRING,
    `target_kpi` STRING,
    `target_kpi_value` DOUBLE,
    `agency_name` STRING,
    `industry` STRING,
    `commercial_audience_name` STRING
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_Market_Order'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `STG_SA_Market_Order`;