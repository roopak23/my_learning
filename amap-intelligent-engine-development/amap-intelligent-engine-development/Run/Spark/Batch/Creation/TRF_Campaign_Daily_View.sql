CREATE TABLE IF NOT EXISTS `TRF_Campaign_Daily_View` (
	`report_id` STRING,
	`date_update` DATE,
	`creation_date` DATE,
	`brand_id` STRING,
	`brand_name` STRING,
	`advertiser_id` STRING,
	`advertiser_name` STRING,
	`industry` STRING,
	`campaign_name` STRING,
	`campaign_remote_id` String,
	`tech_line_remote_id` STRING,
	`market_order_line_details_id` STRING,
	`market_order_line_details_name` STRING,
	`commercial_audience` STRING,
	`start_date` DATE,
	`end_date` DATE,
	`campaign_type` STRING,
	`mold_status` STRING,
	`campaign_status` STRING,
	`objective` STRING,
	`adserver_id` STRING,
	`adserver_name` String,
	`bid_strategy` STRING,
	`actual_pacing` DOUBLE,
	`budget` DOUBLE,
	`target_kpi` STRING,
	`target_kpi_value` DOUBLE,
	`impressions_act` INTEGER,
	`clicks_act` INTEGER,
	`ctr_act` DOUBLE,
	`reach_act` INTEGER,
	`running_days_elapsed` INTEGER,
	`remaining_days` INTEGER,
	`conversions` DOUBLE,
	`cprm` DOUBLE,
	`cpcv` DOUBLE,
	`post_engagement` DOUBLE,
	`player_100` DOUBLE,
	`search_impression_share` DOUBLE,
	`display_impression_share` DOUBLE,
	`budget_act` DOUBLE,
	`cpm` DOUBLE,
	`cpa` DOUBLE,
	`cpc` DOUBLE,
	`cpv` DOUBLE,
	`player_25` DOUBLE,
	`player_50` DOUBLE,
	`player_75` DOUBLE,
	`view` INTEGER,
	`view_rate` DOUBLE,
	`ad_quality_ranking` STRING,
	`pacing_type` STRING,
	`frequency_capping_type` STRING,
	`frequency_capping_quantity` INTEGER,
	`post_reaction` INTEGER,
	`comment` INTEGER,
	`onsite_conversion_post_save` INTEGER,
	`link_click` INTEGER,
	`like` INTEGER,
	`device` STRING,
	`time_of_day` STRING,
	`day_of_week` STRING,
	`time_range` STRING,
	`gender` STRING,
	`age` STRING,
	`family_status` STRING,
	`first_party_data` STRING,
	`second_party_data` STRING,
	`third_party_data` STRING,
	`income` STRING,
	`keyword_match_type` STRING,
	`display_format` STRING,
	`ad_copy` STRING,
	`social_placement` STRING,
	`creative_name` STRING,
	`placement` STRING,
	`network_type` STRING,
	`country` STRING,
	`state` STRING,
	`region` STRING,
	`city` STRING,
	`ad_slot` STRING,
	`keyword` STRING,
	`player_mute` DOUBLE,
	`player_unmute` DOUBLE,
	`player_engaged_views` DOUBLE,
	`player_starts` DOUBLE,
	`player_skip` DOUBLE,
	`sampled_viewed_impressions` DOUBLE,
	`sampled_tracked_impressions` DOUBLE,
	`sampled_in_view_rate` DOUBLE,
	`companion_impressions` DOUBLE,
	`companion_clicks` DOUBLE,
	`unique_id` DOUBLE,
	`frequency_per_unique_id` DOUBLE,
	`data_cost` DOUBLE,
	`deal_id` STRING,
	`site_list_name` STRING,
	`bids` INTEGER,
	`win_rate` DOUBLE,
	`email_total_sent` DOUBLE,
	`unique_open_rate` DOUBLE,
	`unique_click_rate` DOUBLE,
	`sms_total_sent` DOUBLE
)
PARTITIONED BY (partition_date INT)
STORED AS ORC
LOCATION '{{ params.TABLEHOST }}://{{ params.ROOTPATH }}/{{ params.HIVE_DATA_PATH }}/TRF_Campaign_Daily_View'
TBLPROPERTIES("transactional"="true");

MSCK REPAIR TABLE `TRF_Campaign_Daily_View`;