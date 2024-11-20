SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_Campaign_Daily_View partition(partition_date = {{ params.ENDDATE }})
select report_id
,date_act
,creation_date
,brand_id
,brand_name
,advertiser_id
,advertiser_name
,industry
,campaign_name
,order_remote_id
,remote_id
,market_order_line_details_id
,name
,commercial_audience
,start_date
,end_date
,mediatype
,status
,campaign_status
,campaign_objective
,adserver_id
,adserver_name
,bid_strategy
,actual_pacing
,total_budget
,target_kpi
,target_kpi_value
,impressions
,clicks
,CASE WHEN impressions = 0 THEN 0 
ELSE clicks/impressions END AS ctr 
,reach
,running_days_elapsed
,remaining_days
,conversions
,CASE WHEN reach = 0 THEN 0 
ELSE budget/reach END AS cprm
,CASE WHEN player_100 = 0 THEN 0 
ELSE budget/player_100 END AS cpcv
,post_engagement
,player_100
,search_impression_share
,display_impression_share
,budget
,CASE WHEN impressions = 0 THEN 0 
ELSE (budget/impressions) * 100 END AS cpm
,CASE WHEN conversions = 0 THEN 0 
ELSE budget/conversions END AS cpa
,CASE WHEN clicks = 0 THEN 0 
ELSE budget/clicks END AS cpc
,CASE WHEN view = 0 THEN 0 
ELSE budget/view END AS cpv
,player_25
,player_50
,player_75
,view
,view_rate
,ad_quality_ranking
,pacing_type
,frequency_capping_type
,frequency_capping_quantity
,post_reaction
,comment
,onsite_conversion_post_save
,link_click
,`like`
,device
,time_of_day
,day_of_week
,time_range
,gender
,age
,family_status
,first_party_data
,second_party_data
,third_party_data
,income
,keyword_match_type
,display_format
,ad_copy
,social_placement
,creative_name
,placement
,network_type
,country
,state
,region
,city
,ad_slot
,keyword
,player_mute
,player_unmute
,player_engaged_views
,player_starts
,player_skip
,sampled_viewed_impressions
,sampled_tracked_impressions
,sampled_in_view_rate
,companion_impressions
,companion_clicks
,unique_id
,frequency_per_unique_id
,data_cost
,deal_id
,site_list_name
,bids
,CASE WHEN impressions = 0 THEN 0 
ELSE bids/impressions END AS win_rate 
,email_total_sent
,unique_open_rate
,unique_click_rate
,sms_total_sent 
from 
(select a.report_id
	,cast(from_unixtime(a.`date` div 1000, 'yyyy-MM-dd') as date) as date_act
	,TO_DATE(a.creation_date) as creation_date
	,e.brand_id
	,e.brand_name
	,h.advertiser_id
	,h.advertiser_name
	,h.industry
	,e.campaign_name
	,b.order_remote_id
	,c.remote_id
	,d.market_order_line_details_id
	,d.name
	,e.commercial_audience
	,cast(from_unixtime(d.start_date div 1000, 'yyyy-MM-dd') as date) as start_date
	,cast(from_unixtime(d.end_date div 1000, 'yyyy-MM-dd') as date) as end_date
	,d.mediatype
	,d.status
	,e.campaign_status
	,d.campaign_objective
	,f.adserver_id
	,f.adserver_name
	,c.bid_strategy
	,CASE WHEN UPPER(TRIM(f.adserver_type)) = 'GADS' THEN i.total_price
	ELSE d.total_net_price 
	END AS total_budget
	,e.target_kpi
	,e.target_kpi_value
	,a.impressions
	,a.clicks
	,a.reach
	,g.running_days_elapsed
	,g.remaining_days
	,a.conversions
	,CASE
		WHEN UPPER(TRIM(f.adserver_type)) = 'GADS' THEN a.spend_gads
		WHEN UPPER(TRIM(f.adserver_type)) IN ('GAM','TTD','META') THEN a.spend END as budget
	,a.post_engagement
	,a.player_100
	,a.search_impression_share
	,a.display_impression_share
	,a.player_25
	,a.player_50
	,a.player_75
	,a.view
	,a.view_rate
	,a.bids
	,a.win_rate
	,a.ad_quality_ranking
	,c.pacing_type
	,CASE
		WHEN UPPER(TRIM(f.adserver_type)) = 'GAM' THEN d.frequency_capping
		WHEN UPPER(TRIM(f.adserver_type)) IN ('GADS','TTD','META') THEN a.frequency_capping
		END as frequency_capping_type
	,CASE
		WHEN UPPER(TRIM(f.adserver_type)) = 'GAM' THEN d.frequency_capping_quantity
		WHEN UPPER(TRIM(f.adserver_type)) IN ('GADS','TTD','META') THEN a.frequency_capping_quantity
		END as frequency_capping_quantity
	,a.post_reaction
	,a.comment
	,a.onsite_conversion_post_save
	,a.link_click
	,a.`like`
	,a.device
	,a.time_of_day
	,a.day_of_week
	,a.time_range
	,a.gender
	,a.age
	,a.family_status
	,a.first_party_data
	,a.second_party_data
	,a.third_party_data
	,a.income
	,a.keyword_match_type
	,a.display_format
	,a.ad_copy
	,a.social_placement
	,a.creative_name
	,a.placement
	,a.network_type
	,a.country
	,a.state
	,a.region
	,a.city
	,a.ad_slot
	,a.keyword
	,a.player_mute
	,a.player_unmute
	,a.player_engaged_views
	,a.player_starts
	,a.player_skip
	,a.sampled_viewed_impressions
	,a.sampled_tracked_impressions
	,a.sampled_in_view_rate
	,a.companion_impressions
	,a.companion_clicks
	,a.unique_id
	,a.frequency_per_unique_id
	,a.data_cost
	,a.deal_id
	,a.site_list_name
	,f.adserver_type
	,i.pacing as actual_pacing
	,a.email_total_sent
	,a.unique_open_rate
	,a.unique_click_rate
	,a.sms_total_sent 
	FROM trf_past_campaign_performances A
INNER JOIN stg_sa_tech_order B ON a.tech_order_id = b.tech_order_id
INNER JOIN stg_sa_tech_line_details C ON a.tech_line_id = c.tech_line_id
INNER JOIN stg_sa_ad_ops_system F ON a.system_id = f.adserver_id
INNER JOIN trf_fact_input G ON a.tech_line_id = g.tech_line_id and g.`date` = cast(from_unixtime(a.`date` div 1000, 'yyyy-MM-dd') as date)
INNER JOIN stg_sa_market_order_line_details D ON c.market_order_line_details = d.market_order_line_details_id
INNER JOIN stg_sa_market_order E ON d.market_order_id = e.market_order_id
INNER JOIN (SELECT DISTINCT advertiser_id , advertiser_name , brand_name, industry from TRF_advertiser WHERE partition_date = {{ params.ENDDATE }}) H ON e.advertiser_id = h.advertiser_id 
LEFT JOIN (select * from trf_pacing i1 where  i1.partition_date = {{ params.ENDDATE }} ) I ON a.tech_line_id = i.tech_line_id and i.`date` = cast(from_unixtime(a.`date` div 1000, 'yyyy-MM-dd') as date) 
WHERE b.partition_date = {{ params.ENDDATE }} and c.partition_date = {{ params.ENDDATE }} and 
f.partition_date = {{ params.ENDDATE }} and g.partition_date = {{ params.ENDDATE }} and 
d.partition_date = {{ params.ENDDATE }} and e.partition_date = {{ params.ENDDATE }} 
) mi