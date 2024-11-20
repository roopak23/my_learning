
CREATE TABLE IF NOT EXISTS TRF_Am_Lookalike_Historical_Logic
(dp_userid string,
purchase_flag int,
siteuser_flag int,
age_flag int,
gender_flag int,
hist_enrich int,
age_enrich int,
enrich_age_val string,
gender_enrich int,
enrich_gender_val string)
partitioned by (partition_date int)

STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Am_Lookalike_Historical_Logic'
TBLPROPERTIES("transactional"="true");

msck repair table TRF_Am_Lookalike_Historical_Logic;