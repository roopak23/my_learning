CREATE TABLE IF NOT EXISTS `CAR_Geo` (
    `userid` STRING,
	`device` STRING,
    `count_device` INT,
	`country` STRING,
	`count_country` INT,
	`region` STRING,
	`count_region` INT,
	`zipcode` INT,
	`count_zipcode` INT
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (device) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/CAR_Geo'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `CAR_Geo`;
