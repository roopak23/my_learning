SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE CFG_ContentType partition(partition_date = {{ params.ENDDATE }})
SELECT 
    site,
    section,
    IF(instr(subsection_1id, 'car') > 0, 1, 0) AS `automotive`,
    subsection_1id,
    subsection_2id,
    subsection_3id,
    subsection_4id,
    IF(instr(subsection_1id, 'book') > 0, 1, 0) AS `books_and_literature`,
    IF(instr(subsection_1id, 'article') > 0, 1, 0) AS `business_and_finance`,
    IF(instr(subsection_1id, 'page') > 0, 1, 0) AS `careers`,
    IF(instr(subsection_1id, 'edu') > 0, 1, 0) AS `education`,
    IF(instr(subsection_1id, 'event') > 0, 1, 0) AS `events_and_attractions`,
    IF(instr(subsection_1id, 'mum') > 0, 1, 0) AS `family_and_relationships`,
    IF(instr(subsection_1id, 'artist') > 0, 1, 0) AS `fine_art`,
    IF(instr(subsection_1id, 'food') > 0, 1, 0) AS `food_and_drink`,
    IF(instr(subsection_1id, 'food') > 0, 1, 0) AS `healthy_living`,
    IF(instr(subsection_1id, 'vlive') > 0, 1, 0) AS `hobbies_and_interests`,
    IF(instr(subsection_1id, 'home') > 0, 1, 0) AS `home_and_garden`,
    IF(instr(subsection_1id, 'search') > 0, 1, 0) AS `medical_health`,
    IF(instr(subsection_1id, 'movies') > 0, 1, 0) AS `movies`,
    IF(instr(subsection_1id, 'music') > 0 OR instr(subsection_1id, 'artist') > 0 OR instr(subsection_1id, 'playlist') > 0, 1, 0) AS `music_and_audio`,
    IF(instr(subsection_1id, 'article') > 0, 1, 0) AS `news_and_politics`,
    IF(instr(subsection_1id, 'page') > 0, 1, 0) AS `personal_finance`,
    IF(instr(subsection_1id, 'pet') > 0, 1, 0) AS `pets`,
    IF(instr(subsection_1id, 'music') > 0, 1, 0) AS `pop_culture`,
    IF(instr(subsection_1id, 'home') > 0, 1, 0) AS `real_estate`,
    IF(instr(subsection_1id, 'faith') > 0, 1, 0) AS `religion_and_spirituality`,
    IF(instr(subsection_1id, 'science') > 0, 1, 0) AS `science`,
    IF(instr(subsection_1id, 'pay') > 0, 1, 0) AS `shopping`,
    IF(instr(subsection_1id, 'sport') > 0, 1, 0) AS `sports`,
    IF(instr(subsection_1id, 'artist') > 0, 1, 0) AS `style_and_fashion`,
    IF(instr(subsection_1id, 'app') > 0, 1, 0) AS `tech_and_computing`,
    IF(instr(subsection_1id, 'vlive') > 0, 1, 0) AS `television`,
    IF(instr(subsection_1id, 'vlive') > 0, 1, 0) AS `travel`,
    IF(instr(subsection_1id, 'app') > 0, 1, 0) AS `video_gaming`,
    IF(instr(subsection_1id, 'adfloat') > 0, 1, 0) AS `sensitive_topics`
from TRF_SiteHierarchy
where partition_date = {{ params.ENDDATE }}
group by site, section, subsection_1id, subsection_2id, subsection_3id, subsection_4id;
