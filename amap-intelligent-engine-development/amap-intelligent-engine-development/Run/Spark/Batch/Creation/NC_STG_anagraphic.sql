CREATE TABLE IF NOT EXISTS `STG_NC_anagraphic` (
	`sys_datasource` STRING,
    `sys_load_id` BIGINT,
    `sys_created_on` TIMESTAMP,
	`name` STRING,
    `dfp_id` STRING,
    `dfp_name` STRING,
    `source` STRING,
    `methodology` STRING,
    `segmentgroup` STRING,
	`pricing_category` STRING,
	`dfp_size` STRING,
	`total_ubs` int,
    `external_id` STRING,
    `islookalike` STRING,
    `ispremium` STRING,
    `crmaudiencesegment` STRING,
    `status` STRING,
	`has_near_insights` STRING,
	`advertiser` STRING,
    `segmentgroupsubcategory` STRING,
    `segmentgroupcategory` STRING,
    `subcategory` STRING,
    `category` STRING,
    `disable_near_insights` STRING,
	`disable_insights` STRING,
	`near_insight_text` STRING,
	`dt` STRING,
	`adserver_id` STRING
)
PARTITIONED BY (partition_date INT)
-- CLUSTERED BY (status) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_NC_anagraphic'
TBLPROPERTIES("transactional"="true");

msck repair table `STG_NC_anagraphic`;