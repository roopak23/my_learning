-- data_activation.audience_merged_data definition

CREATE TABLE IF NOT EXISTS `audience_merged_data` (
  `userid` text,
  `age` text,
  `gender` text,
  `device` text,
  `country` text,
  `accuracy_gender` double DEFAULT NULL,
  `accuracy_age` double DEFAULT NULL,
  `automotive` bigint(20) DEFAULT NULL,
  `books_and_literature` bigint(20) DEFAULT NULL,
  `business_and_finance` bigint(20) DEFAULT NULL,
  `careers` bigint(20) DEFAULT NULL,
  `education` bigint(20) DEFAULT NULL,
  `events_and_attractions` bigint(20) DEFAULT NULL,
  `family_and_relationships` bigint(20) DEFAULT NULL,
  `fine_art` bigint(20) DEFAULT NULL,
  `food_and_drink` bigint(20) DEFAULT NULL,
  `healthy_living` bigint(20) DEFAULT NULL,
  `hobbies_and_interests` bigint(20) DEFAULT NULL,
  `home_and_garden` bigint(20) DEFAULT NULL,
  `medical_health` bigint(20) DEFAULT NULL,
  `movies` bigint(20) DEFAULT NULL,
  `music_and_audio` bigint(20) DEFAULT NULL,
  `news_and_politics` bigint(20) DEFAULT NULL,
  `personal_finance` bigint(20) DEFAULT NULL,
  `pets` bigint(20) DEFAULT NULL,
  `pop_culture` bigint(20) DEFAULT NULL,
  `real_estate` bigint(20) DEFAULT NULL,
  `religion_and_spirituality` bigint(20) DEFAULT NULL,
  `science` bigint(20) DEFAULT NULL,
  `shopping` bigint(20) DEFAULT NULL,
  `sports` bigint(20) DEFAULT NULL,
  `style_and_fashion` bigint(20) DEFAULT NULL,
  `technology_and_computing` bigint(20) DEFAULT NULL,
  `television` bigint(20) DEFAULT NULL,
  `travel` bigint(20) DEFAULT NULL,
  `video_gaming` bigint(20) DEFAULT NULL,
  `sensitive_topics` bigint(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;