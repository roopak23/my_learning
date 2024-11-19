
CREATE TABLE IF NOT EXISTS api_inventorycheck(
    `id` int,
    `date` DATE,
    `adserver_id` STRING,
    `adserver_adslot_id` STRING,
    `adserver_adslot_name` STRING,
    `audience_name` STRING,
    `metric` STRING,
    `state` STRING,
    `city` STRING,
    `event` STRING,
    `pod_position` STRING,
    `video_position` STRING,
    `future_capacity` INT,
    `booked` INT,
    `reserved` INT,
    `missing_forecast` STRING,
    `missing_segment` STRING,
    `overwriting` STRING,
    `percentage_of_overwriting` STRING,
    `overwritten_impressions` STRING,
    `overwriting_reason` STRING,
    `use_overwrite` STRING,
    `Updated_By` STRING,
    `overwritten_expiry_date` DATE,
    `version` BIGINT
)
PARTITIONED BY (`partition_date` BIGINT) --CLUSTERED BY (status) INTO 5 BUCKETS --> TBD
STORED AS ORC 
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/api_inventorycheck';

msck repair table `api_inventorycheck`;