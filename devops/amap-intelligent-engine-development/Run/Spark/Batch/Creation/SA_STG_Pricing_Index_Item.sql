CREATE TABLE IF NOT EXISTS `STG_SA_Pricing_Index_Item` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `index_id` STRING,
    `pricing_table_id` STRING,
    `name` STRING,
    `index_multiplier` Double,
    `selling_type` STRING,
    `spot_length` Double,
    `audience_name` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (selling_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_Pricing_Index_Item'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_SA_Pricing_Index_Item`;