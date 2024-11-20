CREATE TABLE IF NOT EXISTS `STG_SA_Price_Item` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `price_item_id` STRING,
    `catalog_item_id` STRING,
    `currency` STRING,
    `commercial_audience` STRING,
    `price_list` STRING,
    `price_per_unit` Double,
    `spot_length` Double,
    `unit_of_measure` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (unit_of_measure) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_Price_Item'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_SA_Price_Item`;