DROP TABLE IF EXISTS dq_metaTbl;
CREATE TABLE IF NOT EXISTS `dq_metaTbl`(
  `tablename` string,
  `sequence_id` int,
  `dq_check` string,
  `dq_query` string,
  `blocker` string)
PARTITIONED BY (
  `partition_date` int)

STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/dq_metaTbl'
TBLPROPERTIES("transactional"="true");

msck repair table `dq_metaTbl`;

INSERT INTO
    dq_metaTbl (tablename,sequence_id,dq_check,dq_query,blocker)
VALUES
	 ('STG_NC_taxonomy',1,'validity','select * from stg_nc_taxonomy where length(platform_segment_name)>45','Y'),
	 ('STG_SA_Past_Compaign_Performances',1,'complementss','select case when count(distinct report_id)=4 then ''success'' else ''failure'' end as result from stg_nc_past_performance','N'),
	 ('STG_NA_anagraphic',1,'complementss','select case when count(1)=0 then ''success'' else ''failure'' end as result from stg_sa_anagraphic where total_ubs is null or total_ubs=0','N');

