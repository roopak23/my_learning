-- default.stg_sa_tech_line_details definition

CREATE TABLE IF NOT EXISTS `default.stg_sa_tech_line_details`(
  `sys_datasource` string, 
  `sys_load_id` bigint, 
  `sys_created_on` timestamp, 
  `tech_line_id` string, 
  `tech_line_name` string, 
  `advertiser_id` string, 
  `market_order_line_details` string, 
  `start_date` bigint, 
  `end_date` bigint, 
  `line_type` string, 
  `system_id` string, 
  `remote_id` string, 
  `remote_name` string, 
  `fb_cost_bid_cap` string, 
  `status` string, 
  `bid_strategy` string, 
  `max_bid_amount` double, 
  `budget` double, 
  `pacing_type` string, 
  `quantity` double, 
  `tech_order_id` string, 
  `priority` int, 
  `video_duration` int)
PARTITIONED BY ( 
  `partition_date` int)
ROW FORMAT SERDE 
  'org.apache.hadoop.hive.ql.io.orc.OrcSerde' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat'
  LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/STG_SA_Tech_Line_Details'
TBLPROPERTIES("transactional"="true");


MSCK REPAIR TABLE `stg_sa_tech_line_details`;
