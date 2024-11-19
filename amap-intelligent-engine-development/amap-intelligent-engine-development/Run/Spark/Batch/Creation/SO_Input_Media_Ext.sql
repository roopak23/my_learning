CREATE TABLE IF NOT EXISTS `SO_Input_Media_Ext` (
    `simulation_id` STRING,
    `advertiser_id` STRING,
    `brand_name` STRING,
    `media_type` STRING,
    `field_name` STRING,
    `field_value` STRING,
    `industry` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (media_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/SO_Input_Media_Ext'
TBLPROPERTIES("transactional"="true");

msck repair table `SO_Input_Media_Ext`;