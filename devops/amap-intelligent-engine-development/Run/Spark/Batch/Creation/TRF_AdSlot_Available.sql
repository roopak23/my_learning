CREATE TABLE IF NOT EXISTS `TRF_AdSlot_Available` (
    `catalog_item_id` STRING,
    `name` STRING,
    `sa_adslot_id` STRING,
    `type` STRING,
    `adserver_adslot_id` STRING,
    `adserver_id` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_AdSlot_Available'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_AdSlot_Available`;