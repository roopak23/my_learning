SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_Industry_Insights PARTITION (partition_date = {{ params.ENDDATE }})
SELECT DISTINCT
	E.`date`
	,E.industry
	,E.channel
	,E.media_type
	,E.report_id
	,AVG(E.cpc) OVER (PARTITION BY E.`date`, E.industry) AS cpc
	,AVG(E.ctr) OVER (PARTITION BY E.`date`, E.industry) AS ctr
	,AVG(E.cpcv) OVER (PARTITION BY E.`date`, E.industry) AS cpcv
	,AVG(E.cpv) OVER (PARTITION BY E.`date`, E.industry) AS cpv
	,AVG(E.cpm) OVER (PARTITION BY E.`date`, E.industry) AS cpm
	,AVG(E.view_rate) OVER (PARTITION BY E.`date`, E.industry) AS view_rate
	,SUM(E.impressions) OVER (PARTITION BY E.`date`, E.industry) AS impressions
	,SUM(E.player_25) OVER (PARTITION BY E.`date`, E.industry) AS player_25
	,SUM(E.player_50) OVER (PARTITION BY E.`date`, E.industry) AS player_50
	,SUM(E.player_75) OVER (PARTITION BY E.`date`, E.industry) AS player_75
	,SUM(E.player_100) OVER (PARTITION BY E.`date`, E.industry) AS player_100
	,SUM(E.post_engagement) OVER (PARTITION BY E.`date`, E.industry) AS post_engagement
	,E.time_of_day
	,E.day_of_week
	,E.device
	,E.gender
	,E.age
	,E.keyword
	,E.display_format
	,E.social_placement
	,E.network_type
	,E.country
	,E.state
	,E.region
	,E.city
	,SUM(E.email_total_sent) OVER (PARTITION BY E.`date`, E.industry) AS email_total_sent
	,SUM(E.unique_open_rate) OVER (PARTITION BY E.`date`, E.industry) AS unique_open_rate
	,SUM(E.unique_click_rate) OVER (PARTITION BY E.`date`, E.industry) AS unique_click_rate
	,SUM(E.sms_total_sent) OVER (PARTITION BY E.`date`, E.industry) AS sms_total_sent
FROM (SELECT 
		date_format(from_unixtime(a.`date` DIV 1000),'MMM YYYY') as `date`
		,a.tech_line_id
		,d.industry
		,c.ad_server_type AS channel
		,c.mediatype as media_type
		,a.report_id
		,a.cpc
		,a.ctr
		,a.cpcv
		,a.cpv
		,a.cpm
		,a.view_rate
		,a.impressions
		,CASE WHEN UPPER(TRIM(adserver_type)) = 'GADS'  THEN (player_25 * impressions) ELSE player_25  END AS player_25
		,CASE WHEN UPPER(TRIM(adserver_type)) = 'GADS'  THEN (player_50 * impressions) ELSE player_50  END AS player_50
		,CASE WHEN UPPER(TRIM(adserver_type)) = 'GADS'  THEN (player_75 * impressions) ELSE player_75  END AS player_75
		,CASE WHEN UPPER(TRIM(adserver_type)) = 'GADS'  THEN (player_100 * impressions) ELSE player_100  END AS player_100
		,a.post_engagement
		,a.time_of_day
		,a.day_of_week
		,a.device
		,a.gender
		,a.age
		,a.keyword
		,a.display_format
		,a.social_placement
		,a.network_type
		,a.country
		,a.state
		,a.region
		,a.city
		,a.email_total_sent
		,a.unique_open_rate
		,a.unique_click_rate
		,a.sms_total_sent
	FROM TRF_Past_Campaign_Performances A
	INNER JOIN STG_SA_TECH_LINE_DETAILS B ON A.tech_line_id = B.tech_line_id
	INNER JOIN STG_SA_MARKET_ORDER_LINE_DETAILS C ON B.market_order_line_details = C.market_order_line_details_id
	INNER JOIN STG_SA_MARKET_ORDER D ON C.market_order_id = D.market_order_id
	INNER JOIN STG_SA_AD_OPS_SYSTEM E ON A.system_id = E.adserver_id
	WHERE B.partition_date = {{ params.ENDDATE }} AND  C.partition_date = {{ params.ENDDATE }} AND  D.partition_date = {{ params.ENDDATE }} AND  E.partition_date = {{ params.ENDDATE }}
) E;