
CREATE TABLE IF NOT EXISTS DP_Car_Sociodemo_Enriched
(dp_userid string,
prediction_gender string,
pred_prob_max_gender float,
prediction_probability_gender string,
prediction_age string,
pred_prob_max_age float,
predicted_probability_age string,
known_user int,
city string,
country string)
partitioned by (partition_date int)

STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/DP_Car_Sociodemo_Enriched'
TBLPROPERTIES("transactional"="true");

msck repair table DP_Car_Sociodemo_Enriched;  