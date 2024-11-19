SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_SAR_Views partition(partition_date = {{ params.ENDDATE }})
SELECT MAX(a.url_day) as `date`
	,a.site
	,COUNT(a.dmp_userid)
	,COUNT(DISTINCT a.dmp_userid)
	,concat_ws(',', MAX(b.interest))
FROM TRF_SiteHierarchy as a
JOIN(
   SELECT site
      ,collect_set(m_key)  as interest
   FROM (
      SELECT site
	  ,partition_date
	  , map("automotive", automotive,"books_and_literature", books_and_literature,"business_and_finance", business_and_finance,"careers", careers,"education", education,"events_and_attractions", events_and_attractions,"family_and_relationships", family_and_relationships,"fine_art", fine_art,"food_and_drink", food_and_drink,"healthy_living", healthy_living,"hobbies_and_interests", hobbies_and_interests,"home_and_garden", home_and_garden,"medical_health", medical_health,"movies", movies,"music_and_audio", music_and_audio,"news_and_politics", news_and_politics,"personal_finance", personal_finance,"pets", pets,"pop_culture", pop_culture,"real_estate", real_estate,"religion_and_spirituality", religion_and_spirituality,"science", science,"shopping", shopping,"sports", sports,"style_and_fashion", style_and_fashion,"technology_and_computing", tech_and_computing,"television", television,"travel", travel,"video_gaming", video_gaming,"sensitive_topics", sensitive_topics) as map1
      FROM cfg_contenttype) as t1
		LATERAL VIEW explode(map1) xyz as m_key, m_val
   WHERE m_val >0
      AND partition_date = {{ params.ENDDATE }}
   GROUP BY site, partition_date
   ) AS b ON a.site = b.site
WHERE a.partition_date = {{ params.ENDDATE }}
GROUP BY a.site;
