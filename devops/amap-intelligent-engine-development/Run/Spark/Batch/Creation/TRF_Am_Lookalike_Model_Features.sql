CREATE TABLE IF NOT EXISTS TRF_Am_Lookalike_Model_Features
(model_name string,
attributes string)

STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Am_Lookalike_Model_Features'
TBLPROPERTIES("transactional"="true");

msck repair table TRF_Am_Lookalike_Model_Features;