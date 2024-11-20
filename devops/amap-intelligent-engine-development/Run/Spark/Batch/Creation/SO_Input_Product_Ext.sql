CREATE TABLE IF NOT EXISTS `SO_Input_Product_Ext` (
    `simulation_id` STRING,
    `advertise_id` STRING,
    `brand_name` STRING,
    `catalog_level` INT,
    `record_type` STRING,
    `catalog_item_id` STRING,    
    `field_name` STRING,
    `field_value` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (record_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/SO_Input_Product_Ext'
TBLPROPERTIES("transactional"="true");

msck repair table `SO_Input_Product_Ext`;