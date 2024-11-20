CREATE TABLE IF NOT EXISTS `TRF_Adslot_Hierarchy` (
    `id` STRING,
    `adserver_id` STRING,
    `adserver_adslot_child_id` STRING,
    `adserver_adslot_parent_id` STRING,
    `adslot_child_id` STRING,
    `adslot_parent_id` STRING,
    `adserver_adslot_level` INT
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (record_type) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Adslot_Hierarchy'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_Adslot_Hierarchy`;