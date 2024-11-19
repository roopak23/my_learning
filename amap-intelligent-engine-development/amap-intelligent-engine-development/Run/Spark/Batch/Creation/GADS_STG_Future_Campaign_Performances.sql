CREATE TABLE IF NOT EXISTS `STG_GADS_Future_Campaign_Performances` (
	`sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
	`customer_id` STRING,
	`account_id` STRING,
	`adgroup_id` STRING,
	`keywordplan_id` STRING,
	`keywordplan_campaign_id` STRING,
	`keywordplan_adgroup_id` STRING,
	`keywordplan_adgroup_keywords_id` STRING,
	`impressions` DOUBLE,
	`ctr` DOUBLE,
	`average_cpc` INT,
	`clicks` DOUBLE,
	`cost_micros` INT
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_GADS_Future_Campaign_Performances'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `STG_GADS_Future_Campaign_Performances`;