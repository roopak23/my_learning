SET hive.auto.convert.join= FALSE;


DROP TABLE IF EXISTS TRF_Monitoring_Insights_TMP;


CREATE TABLE TRF_Monitoring_Insights_TMP AS
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
,campaign_type
,status
,campaign_status
,campaign_objective
,mi.adserver_id
,adserver_name
,bid_strategy
,actual_pacing
,total_budget
,target_kpi
,target_kpi_value
,SUM(impressions) OVER (PARTITION BY id ORDER BY date_act) as impressions_act 
,SUM(clicks) OVER (PARTITION BY id ORDER BY date_act) as clicks_act
,(SUM(clicks) OVER (PARTITION BY id ORDER BY date_act)/SUM(impressions) OVER (PARTITION BY id ORDER BY date_act)) * 100 as ctr_act
,SUM(reach) OVER (PARTITION BY id ORDER BY date_act)/running_days_elapsed as reach_act
,running_days_elapsed
,remaining_days  
,SUM(conversions) OVER (PARTITION BY id ORDER BY date_act) as conversions_act 
,CASE
	WHEN SUM(reach) OVER (PARTITION BY id ORDER BY date_act) = 0 
	THEN 0
	ELSE 
	SUM(budget) OVER (PARTITION BY id ORDER BY date_act)/SUM(reach) OVER (PARTITION BY id ORDER BY date_act) 
	END AS cprm
,CASE
	WHEN SUM(player_100) OVER (PARTITION BY id ORDER BY date_act) = 0 
	THEN 0 
	ELSE 
	SUM(budget) OVER (PARTITION BY id ORDER BY date_act)/SUM(player_100) OVER (PARTITION BY id ORDER BY date_act) 
	END AS cpcv
,post_engagement
,CASE WHEN UPPER(TRIM(adserver_type)) = 'GADS' 
	THEN SUM(player_100) OVER (PARTITION BY id ORDER BY date_act)*1000 
	ELSE 
	SUM(player_100) OVER (PARTITION BY id ORDER BY date_act) 
	END AS player_100
,SUM(search_impression_share) OVER (PARTITION BY id ORDER BY date_act)/running_days_elapsed  AS search_impression_share
,SUM(display_impression_share) OVER (PARTITION BY id ORDER BY date_act)/running_days_elapsed AS display_impression_share
,SUM(budget) OVER (PARTITION BY id ORDER BY date_act) as budget_act
,CASE
	WHEN SUM(impressions) OVER (PARTITION BY id ORDER BY date_act) = 0 
	THEN 0 
	ELSE 
	SUM(budget) OVER (PARTITION BY id ORDER BY date_act)/SUM(impressions) OVER (PARTITION BY id ORDER BY date_act)*1000 
	END AS cpm
,CASE
	WHEN SUM(conversions) OVER (PARTITION BY id ORDER BY date_act) = 0 
	THEN 0 
	ELSE 
	SUM(budget) OVER (PARTITION BY id ORDER BY date_act)/SUM(conversions) OVER (PARTITION BY id ORDER BY date_act) 
	END AS cpa
,CASE
	WHEN SUM(clicks) OVER (PARTITION BY id ORDER BY date_act) = 0 
	THEN 0 
	ELSE 
	SUM(budget) OVER (PARTITION BY id ORDER BY date_act)/SUM(clicks) OVER (PARTITION BY id ORDER BY date_act) 
	END AS cpc
,CASE
	WHEN SUM(view) OVER (PARTITION BY id ORDER BY date_act) = 0 
	THEN 0 
	ELSE 
	SUM(budget) OVER (PARTITION BY id ORDER BY date_act)/SUM(view) OVER (PARTITION BY id ORDER BY date_act) 
	END AS cpv
,CASE WHEN UPPER(TRIM(adserver_type)) = 'GADS' 
	THEN SUM(player_25) OVER (PARTITION BY id ORDER BY date_act)*1000 
	ELSE 
	SUM(player_25) OVER (PARTITION BY id ORDER BY date_act) 
	END AS player_25
,CASE WHEN UPPER(TRIM(adserver_type)) = 'GADS' 
	THEN SUM(player_50) OVER (PARTITION BY id ORDER BY date_act)*1000 
	ELSE 
	SUM(player_50) OVER (PARTITION BY id ORDER BY date_act) 
	END AS player_50
,CASE WHEN UPPER(TRIM(adserver_type)) = 'GADS' 
	THEN SUM(player_75) OVER (PARTITION BY id ORDER BY date_act)*1000 
	ELSE 
	SUM(player_75) OVER (PARTITION BY id ORDER BY date_act) 
	END AS player_75
,view
,CASE WHEN SUM(impressions) OVER (PARTITION BY id ORDER BY date_act) = 0
	THEN 0
	ELSE
	SUM(view) OVER (PARTITION BY id ORDER BY date_act)/SUM(impressions) OVER (PARTITION BY id ORDER BY date_act) 
	END AS view_rate
,ad_quality_ranking
,pacing_type
,frequency_capping_type
,frequency_capping_quantity
,SUM(post_reaction) OVER (PARTITION BY id ORDER BY date_act) AS post_reaction
,SUM(comment) OVER (PARTITION BY id ORDER BY date_act) AS comment
,SUM(onsite_conversion_post_save) OVER (PARTITION BY id ORDER BY date_act) AS onsite_conversion_post_save
,SUM(link_click) OVER (PARTITION BY id ORDER BY date_act) AS link_click
,SUM(`like`) OVER (PARTITION BY id ORDER BY date_act) AS `like`
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
,SUM(player_mute) OVER (PARTITION BY id ORDER BY date_act) AS player_mute
,SUM(player_unmute) OVER (PARTITION BY id ORDER BY date_act) AS player_unmute
,SUM(player_engaged_views) OVER (PARTITION BY id ORDER BY date_act) AS player_engaged_views
,SUM(player_starts) OVER (PARTITION BY id ORDER BY date_act) AS player_starts
,SUM(player_skip) OVER (PARTITION BY id ORDER BY date_act) AS player_skip
,SUM(sampled_viewed_impressions) OVER (PARTITION BY id ORDER BY date_act) AS sampled_viewed_impressions
,SUM(sampled_tracked_impressions) OVER (PARTITION BY id ORDER BY date_act) AS sampled_tracked_impressions
,SUM(sampled_viewed_impressions) OVER (PARTITION BY id ORDER BY date_act)/SUM(sampled_tracked_impressions) OVER (PARTITION BY id ORDER BY date_act) as sampled_in_view_rate
,SUM(companion_impressions) OVER (PARTITION BY id ORDER BY date_act) AS companion_impressions
,SUM(companion_clicks) OVER (PARTITION BY id ORDER BY date_act) AS companion_clicks
,SUM(unique_id) OVER (PARTITION BY id ORDER BY date_act) AS unique_id
,SUM(frequency_per_unique_id) OVER (PARTITION BY id ORDER BY date_act) AS frequency_per_unique_id
,SUM(data_cost) OVER (PARTITION BY id ORDER BY date_act) AS data_cost
,deal_id
,site_list_name
,SUM(bids) OVER (PARTITION BY id ORDER BY date_act) AS bids
,SUM(bids) OVER (PARTITION BY id ORDER BY date_act)/SUM(impressions) OVER (PARTITION BY id ORDER BY date_act) as win_rate
,SUM(email_total_sent) OVER (PARTITION BY id ORDER BY date_act) AS email_total_sent
,SUM(unique_open_rate) OVER (PARTITION BY id ORDER BY date_act) AS unique_open_rate
,SUM(unique_click_rate) OVER (PARTITION BY id ORDER BY date_act) AS unique_click_rate
,SUM(sms_total_sent) OVER (PARTITION BY id ORDER BY date_act) AS sms_total_sent
,id
,rank() over (partition by id order by date_act desc) as rnk
,forecasted_quantity
,forecasted_pacing
,tech_order_id
,tech_line_id
,frequency_cap
,mi.adserver_adslot_id
,mi.adserver_adslot_name
,tah.adserver_adslot_level adserver_adslot_level
,tah.adserver_adslot_level  + 1 - MIN(tah.adserver_adslot_level) OVER (PARTITION BY market_order_id ) order_adslot_level
from 
(select DISTINCT 
	case when UPPER(TRIM(a.report_id)) = 'REPORT0' then c.tech_line_id 
	else 
	md5(concat(nvl(a.`report_id`,'null'),'_',`market_order_line_details_id`,'_',nvl(`device`,'null'),'_',nvl(`time_of_day`,'null'),'_',nvl(`day_of_week`,'null'),'_',nvl(`time_range`,'null'),'_',nvl(`gender`,'null'),'_',nvl(`age`,'null'),'_',nvl(`family_status`,'null'),'_',nvl(`first_party_data`,'null'),'_',nvl(`second_party_data`,'null'),'_',nvl(`third_party_data`,'null'),'_',nvl(`income`,'null'),'_',nvl(`keyword_match_type`,'null'),'_',nvl(`display_format`,'null'),'_',nvl(`ad_copy`,'null'),'_',nvl(`social_placement`,'null'),'_',nvl(`creative_name`,'null'),'_',nvl(`placement`,'null'),'_',nvl(`network_type`,'null'),'_',nvl(`country`,'null'),'_',nvl(`state`,'null'),'_',nvl(`region`,'null'),'_',nvl(`city`,'null'),'_',nvl(`ad_slot`,'null'),'_',nvl(`keyword`,'null'),'_',nvl(a.`adserver_adslot_id`,'null'))) end as id
	,a.report_id
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
	,d.mediatype as campaign_type
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
	,g.forecasted_quantity
	,g.forecasted_pacing
	,b.tech_order_id
	,c.tech_line_id
	,e.market_order_id
	,d.frequency_cap
	,a.adserver_adslot_id
	,a.adserver_adslot_name
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
LEFT JOIN (select adserver_id,adserver_adslot_child_id,adserver_adslot_level from trf_adslot_hierarchy where partition_date = {{ params.ENDDATE }}  ) tah ON (tah.adserver_id =  mi.adserver_id AND tah.adserver_adslot_child_id = mi.adserver_adslot_id);


INSERT OVERWRITE TABLE TRF_Monitoring_Insights partition(partition_date = {{ params.ENDDATE }})
SELECT * FROM TRF_Monitoring_Insights_TMP;