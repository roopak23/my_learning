CREATE TABLE IF NOT EXISTS `TRF_Inventory_Check` (
    `date` DATE,
    `system_id` STRING,
    `remote_id` STRING,
    `ad_format_id` STRING,
    `breadcrumb` STRING,
    `future_capacity` INT,
    `availability` INT,
    `audience` STRING,
    `audience_id` STRING,
    `metric` STRING
    )
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Inventory_Check'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_Inventory_Check`;