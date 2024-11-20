CREATE TABLE IF NOT EXISTS `STG_Date` (
    `sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
    `date ` DATE,
    `day` STRING,
    `month` INT,
    `holiday` INT,
    `summer_period` INT,
    `christmas_period ` INT
    )
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_Date'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_Date`;