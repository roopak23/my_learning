CREATE TABLE IF NOT EXISTS `trg_user_segment_mapping` (
  userid                  STRING,
  segment_id              STRING
)
PARTITIONED BY (partition_date INT)
--CLUSTERED BY (segment_id) INTO 5 BUCKETS --> TBD
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/trg_user_segment_mapping'
TBLPROPERTIES("transactional"="true");


CREATE TABLE IF NOT EXISTS SGM_METADATA (
   SEGMENT_ID STRING,
   ENTITY STRING,
   LOGICAL_NAME STRING,
   BUSINESS_NAME STRING,
   SEGMENT_TYPE  STRING,
   ACTIVE STRING
)
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/SGM_METADATA'
TBLPROPERTIES("transactional"="false");

--
-- config table  ava_config
--
CREATE TABLE IF NOT EXISTS amap_config (
  last_date STRING,
  backward_period int,
  accesses int,
  views int,
  playback_duration decimal(12,4),
  historic_agg_limit_qs int,
  historic_var_limit_qs int,
  historic_raw_limit_qs int,
  historic_kpi_limit_qs int,
  historic_agg_limit_qv int,
  historic_var_limit_qv int,
  historic_raw_limit_qv int,
  log_retention_period_qv int,
  log_retention_period_qs int
)
ROW FORMAT DELIMITED FIELDS
TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/amap_config'
TBLPROPERTIES("transactional"="false");

msck repair table `trg_user_segment_mapping`;
msck repair table `SGM_METADATA`;
msck repair table `amap_config`;

# INSERT OVERWRITE TABLE amap_config
# SELECT setup.*
# FROM
#   (SELECT -- contruction needed for SPARK engine
#     '${hivevar:ENDDATE}',
#     ${hivevar:BACKWARD_PERIOD},
#     ${hivevar:MIN_REQUIRED_ACCESSES},
#     ${hivevar:MIN_AMOUNT_OF_VIEWS},
#     ${hivevar:PLAYBACK_TIME},
#     ${hivevar:HISTORIC_AGG_LIMIT_QS},
#     ${hivevar:HISTORIC_VAR_LIMIT_QS},
#     ${hivevar:HISTORIC_RAW_LIMIT_QS},
#     ${hivevar:HISTORIC_KPI_LIMIT_QS},
#     ${hivevar:HISTORIC_AGG_LIMIT_QV},
#     ${hivevar:HISTORIC_VAR_LIMIT_QV},
#     ${hivevar:HISTORIC_RAW_LIMIT_QV},
#     ${hivevar:LOG_RETENTION_PERIOD_QV},
#     ${hivevar:LOG_RETENTION_PERIOD_QS}
#   ) setup ;

