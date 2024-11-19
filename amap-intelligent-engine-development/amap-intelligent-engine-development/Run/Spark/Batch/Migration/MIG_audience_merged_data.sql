Select
	A.userid AS userid,
	C.age AS age,
	C.gender AS gender,
	B.device AS device,
	B.country AS country,
	C.accuracy_gender AS accuracy_gender,
	C.accuracy_age AS accuracy_age,
	A.automotive AS automotive,
	A.books_and_literature AS books_and_literature,
	A.business_and_finance AS business_and_finance,
	A.careers AS careers,
	A.education AS education,
	A.events_and_attractions AS events_and_attractions,
	A.family_and_relationships AS family_and_relationships,
	A.fine_art AS fine_art,
	A.food_and_drink AS food_and_drink,
	A.healthy_living AS healthy_living,
	A.hobbies_and_interests AS hobbies_and_interests,
	A.home_and_garden AS home_and_garden,
	A.medical_health AS medical_health,
	A.movies AS movies,
	A.music_and_audio AS music_and_audio,
	A.news_and_politics AS news_and_politics,
	A.personal_finance AS personal_finance,
	A.pets AS pets,
	A.pop_culture AS pop_culture,
	A.real_estate AS real_estate,
	A.religion_and_spirituality AS religion_and_spirituality,
	A.science AS science,
	A.shopping AS shopping,
	A.sports AS sports,
	A.style_and_fashion AS style_and_fashion,
	A.tech_and_computing AS technology_and_computing,
	A.television AS television,
	A.travel AS travel,
	A.video_gaming AS video_gaming,
	A.sensitive_topics AS sensitive_topics
from
	CAR_Interest A
left join CAR_Geo B on
	A.userid = B.userid
	and A.partition_date = B.partition_date
left join LAL_SocioDemo C on
	A.userid = C.userid
	and A.partition_date = C.partition_date
Where A.partition_date = {{ params.ENDDATE }}