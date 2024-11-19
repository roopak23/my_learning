SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE CAR_Interest partition(partition_date = {{ params.ENDDATE }})
SELECT
	b.userid,
	SUM(IF(c.automotive = TRUE, 1, 0)) as automotive,
	SUM(IF(c.books_and_literature = TRUE, 1, 0)) as books_and_literature,
	SUM(IF(c.business_and_finance = TRUE, 1, 0)) as business_and_finance,
	SUM(IF(c.careers = TRUE, 1, 0)) as careers,
	SUM(IF(c.education = TRUE, 1, 0)) as education,
	SUM(IF(c.events_and_attractions = TRUE, 1, 0)) as events_and_attractions,
	SUM(IF(c.family_and_relationships = TRUE, 1, 0)) as family_and_relationships,
	SUM(IF(c.fine_art = TRUE, 1, 0)) as fine_art,
	SUM(IF(c.food_and_drink = TRUE, 1, 0)) as food_and_drink,
	SUM(IF(c.healthy_living = TRUE, 1, 0)) as healthy_living,
	SUM(IF(c.hobbies_and_interests = TRUE, 1, 0)) as hobbies_and_interests,
	SUM(IF(c.home_and_garden = TRUE, 1, 0)) as home_and_garden,
	SUM(IF(c.medical_health = TRUE, 1, 0)) as medical_health,
	SUM(IF(c.movies = TRUE, 1, 0)) as movies,
	SUM(IF(c.music_and_audio = TRUE, 1, 0)) as music_and_audio,
	SUM(IF(c.news_and_politics = TRUE, 1, 0)) as news_and_politics,
	SUM(IF(c.personal_finance = TRUE, 1, 0)) as personal_finance,
	SUM(IF(c.pets = TRUE, 1, 0)) as pets,
	SUM(IF(c.pop_culture = TRUE, 1, 0)) as pop_culture,
	SUM(IF(c.real_estate = TRUE, 1, 0)) as real_estate,
	SUM(IF(c.religion_and_spirituality = TRUE, 1, 0)) as religion_and_spirituality,
	SUM(IF(c.science = TRUE, 1, 0)) as science,
	SUM(IF(c.shopping = TRUE, 1, 0)) as shopping,
	SUM(IF(c.sports = TRUE, 1, 0)) as sports,
	SUM(IF(c.style_and_fashion = TRUE, 1, 0)) as style_and_fashion,
	SUM(IF(c.tech_and_computing = TRUE, 1, 0)) as technology_and_computing,
	SUM(IF(c.television = TRUE, 1, 0)) as television,
	SUM(IF(c.travel = TRUE, 1, 0)) as travel,
	SUM(IF(c.video_gaming = TRUE, 1, 0)) as video_gaming,
	SUM(IF(c.sensitive_topics = TRUE, 1, 0)) as sensitive_topics
FROM TRF_SiteHierarchy AS a
	JOIN AUD_STG_UserMatching AS b ON b.dmp_userid = a.dmp_userid  AND b.partition_date = a.partition_date
	LEFT JOIN cfg_contenttype  AS c ON c.site = a.site
									AND c.`section` = a.`section`
									AND c.subsection_1id = a.subsection_1id
									AND c.subsection_2id = a.subsection_2id
									AND c.subsection_3id = a.subsection_3id
									AND c.subsection_4id = a.subsection_4id
WHERE a.partition_date ={{ params.ENDDATE }}
GROUP BY b.userid
;