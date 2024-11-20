CREATE TABLE IF NOT EXISTS `CAR_Interest` (
    `userid` STRING,
	`automotive` INT,
    `books_and_literature` INT,
	`business_and_finance` INT,
	`careers` INT,
	`education` INT,
	`events_and_attractions` INT,
	`family_and_relationships` INT,
	`fine_art` INT,
	`food_and_drink` INT,
	`healthy_living` INT,
	`hobbies_and_interests` INT,
	`home_and_garden` INT,
	`medical_health` INT,
	`movies` INT,
	`music_and_audio` INT,
	`news_and_politics` INT,
	`personal_finance` INT,
	`pets` INT,
	`pop_culture` INT,
	`real_estate` INT,
	`religion_and_spirituality` INT,
	`science` INT,
	`shopping` INT,
	`sports` INT,
	`style_and_fashion` INT,
	`tech_and_computing` INT,
	`television` INT,
	`travel` INT,
	`video_gaming` INT,
	`sensitive_topics` INT
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (careers) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/CAR_Interest'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `CAR_Interest`;
