CREATE TABLE IF NOT EXISTS `TRF_AdServer_InvHistorical` (
    `date` date,
    `adserver_adslot_id` STRING,
    `adserver_adslot_name` STRING,
    `total_code_served_count` INT,
    `unifilled_impression` INT,
	`unmatched_ad_requests` INT,
	`adserver_id` STRING,
    `metric` STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (metric) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_AdServer_InvHistorical'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_AdServer_InvHistorical`;