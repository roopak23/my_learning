CREATE TABLE IF NOT EXISTS `ML_InvForecastingInput` (
    `date` date, 
    `adserver_id` string, 
    `adserver_adslot_id` string, 
    `adserver_target_remote_id` string, 
    `adserver_target_name` string, 
    `adserver_target_type` string, 
    `historical_capacity` int, 
    `metric` string, 
    `adserver_adslot_name` string)
    
PARTITIONED BY ( 
    `partition_date` int)
--CLUSTERED BY (metric) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/ML_InvForecastingInput'
TBLPROPERTIES("transactional"="true");

msck repair table `ML_InvForecastingInput`;