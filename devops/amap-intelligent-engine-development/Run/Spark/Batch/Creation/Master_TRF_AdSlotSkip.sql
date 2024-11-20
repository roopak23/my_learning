CREATE TABLE IF NOT EXISTS `TRF_Master_AdSlotSkip` (
	`adserver_adslot_id` STRING
)
--CLUSTERED BY (status) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Master_AdSlotSkip'
TBLPROPERTIES("transactional"="true");

msck repair table `TRF_Master_AdSlotSkip`;