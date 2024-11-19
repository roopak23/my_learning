SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_Days_Line PARTITION (partition_date = {{ params.ENDDATE }})
SELECT a.advertiser_id
	,a.advertiser_name
	,b.brand_name
    ,b.brand_id
	,a.industry
	,b.market_order_line_details_id  		--> PK
	,b.media_type
	,b.unit_of_measure as unit_type
	,b.total_price
	,b.count_days
	,b.market_product_type_id
	,b.discount
	,b.objective
FROM (SELECT DISTINCT advertiser_id , advertiser_name , brand_name ,brand_id, industry from TRF_advertiser WHERE partition_date = {{ params.ENDDATE }}) a
JOIN (
	SELECT n.market_order_line_details_id
		,n.advertiser_id
		,n.brand_name
		,n.brand_id
		,n.mediatype AS media_type
		,n.unit_of_measure
		,n.total_price
		,datediff(max(n.end_date), min(n.start_date)) AS count_days
		,n.market_product_type AS market_product_type_id
		,avg(nvl(n.discount_ds,n.discount_ssp)) as discount
		,max(n.campaign_objective) as objective
	FROM TRF_market_order_line_details n
	WHERE n.partition_date = {{ params.ENDDATE }}
	GROUP BY
	    n.market_order_line_details_id
		,n.advertiser_id
		,n.brand_name
		,n.brand_id
		,n.mediatype
		,n.unit_of_measure
		,n.total_price
		,n.market_product_type
	) b ON (
		a.advertiser_id = b.advertiser_id AND coalesce(nullif(a.brand_id,''),' ') = coalesce(nullif(b.brand_id,''),' ')
		)
