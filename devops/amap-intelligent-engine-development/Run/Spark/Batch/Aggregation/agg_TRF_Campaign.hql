SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_Campaign PARTITION (partition_date = {{ params.ENDDATE }})
SELECT distinct 
	a.advertiser_id
	,a.tech_line_id
	,a.tech_order_id
	,a.tech_line_name
	,b.market_order_id
	,a.market_order_line_details as market_order_line_details_id
	,a.system_id
	,a.remote_id
	,a.remote_name
	,cast(from_unixtime(a.start_date div 1000, 'yyyy-MM-dd') as date) as start_date
	,cast(from_unixtime(a.end_date div 1000, 'yyyy-MM-dd') as date) as end_date
	,(DATEDIFF(cast(from_unixtime(a.end_date div 1000, 'yyyy-MM-dd') as date),cast(from_unixtime(a.start_date div 1000, 'yyyy-MM-dd') as date))+1) as duration
	,b.unit_net_price
	,b.discount_ds
	,b.discount_ssp
	,b.total_net_price as budget
	,b.unit_of_measure as metric
	,b.quantity as target_quantity
	,b.mediatype
	,case when a.pacing_type is NULL then 'EVENLY' else a.pacing_type end as delivery_rate_type
	,b.campaign_objective as objective
	,b.format as ad_format_id
	,c.commercial_audience
	,b.carrier_targeting
	,b.custom_targeting
	,b.daypart_targeting
	,b.device_targeting
	,b.geo_targeting
	,b.os_targeting
	,b.time_slot_targeting
	,b.weekpart_targeting
	,d.creative_ad_type
	,d.creative_size
	,a.priority
	,a.line_type
	,b.frequency_capping
	,b.frequency_capping_quantity
	,b.unit_price
	,h.adserver_target_remote_id
	,h.adserver_target_name
	,h.adserver_target_type
	,h.adserver_target_category
	,g.industry
	,b.audience_name
	,b.frequency_cap
FROM STG_SA_Tech_Line_Details a 
INNER JOIN STG_SA_Market_Order_Line_Details b on a.market_order_line_details = b.market_order_line_details_id
	AND a.partition_date = b.partition_date
INNER JOIN STG_SA_Creative d on a.tech_line_id = d.tech_line_id
	AND a.partition_date = d.partition_date
INNER JOIN STG_sa_market_order c on b.market_order_id = c.market_order_id 
	AND a.partition_date = C.partition_date
INNER JOIN STG_SA_Account g on c.advertiser_id = g.account_id
    AND c.partition_date = g.partition_date
INNER JOIN STG_SA_Tech_Line_Targeting e ON a.tech_line_id = e.tech_line_id 
	AND a.partition_date = e.partition_date
LEFT JOIN STG_SA_Targeting h ON e.adserver_target_remote_id = h.adserver_target_remote_id 
	AND e.partition_date = h.partition_date 
WHERE a.partition_date = {{ params.ENDDATE }};