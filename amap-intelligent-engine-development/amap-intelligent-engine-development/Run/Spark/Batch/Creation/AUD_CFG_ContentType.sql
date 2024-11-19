CREATE TABLE IF NOT EXISTS `CFG_ContentType` (
    `site` STRING,
	`section` STRING,
    `automotive` STRING,
	`subsection_1id` STRING,
	`subsection_2id` STRING,
	`subsection_3id` STRING,
	`subsection_4id` STRING,
	`books_and_literature` Decimal,
	`business_and_finance` Decimal,
	`careers` Decimal,
	`education` Decimal,
	`events_and_attractions` Decimal,
	`family_and_relationships` Decimal,
	`fine_art` Decimal,
	`food_and_drink` Decimal,
	`healthy_living` Decimal,
	`hobbies_and_interests` Decimal,
	`home_and_garden` Decimal,
	`medical_health` Decimal,
	`movies` Decimal,
	`music_and_audio` Decimal,
	`news_and_politics` Decimal,
	`personal_finance` Decimal,
	`pets` Decimal,
	`pop_culture` Decimal,
	`real_estate` Decimal,
	`religion_and_spirituality` Decimal,
	`science` Decimal,
	`shopping` Decimal,
	`sports` Decimal,
	`style_and_fashion` Decimal,
	`tech_and_computing` Decimal,
	`television` Decimal,
	`travel` Decimal,
	`video_gaming` Decimal,
	`sensitive_topics` Decimal
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (section) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/CFG_ContentType'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `CFG_ContentType`;
