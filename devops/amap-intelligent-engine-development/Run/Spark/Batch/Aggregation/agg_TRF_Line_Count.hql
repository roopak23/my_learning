SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_Line_Count PARTITION (partition_date = {{ params.ENDDATE }})
SELECT 
	c.advertiser_id   		                --> PK
	,c.advertiser_name
	,c.brand_name
	,c.brand_id  			                --> PK
	,c.media_type     		                --> PK
	,c.unit_type     		                --> PK
	,sum(c.count_lines) AS count_lines
	,c.market_product_type_id               --> PK
FROM (
	SELECT b.advertiser_id
		,b.advertiser_name
		,b.brand_name
	    ,b.brand_id
		,b.media_type
		,b.unit_of_measure as unit_type
		,b.market_order_id
		,count(*) AS count_lines
		,b.market_product_type_id
	FROM
	 (SELECT
	n.advertiser_id
	,n.advertiser_name
	,n.mediatype AS media_type
	,n.unit_of_measure
	,n.market_order_id
	,n.market_product_type AS market_product_type_id
	,n.brand_name
	,n.brand_id
	,n.partition_date
	FROM TRF_market_order_line_details N
	WHERE N.partition_date = {{ params.ENDDATE }}) b
	GROUP BY b.advertiser_id
		,b.advertiser_name
		,b.brand_name
		,b.brand_id
		,b.media_type
		,b.unit_of_measure
		,b.market_order_id
		,b.market_product_type_id
	)c
	GROUP BY 
	c.advertiser_id
	,c.advertiser_name
	,c.brand_name
	,c.brand_id
	,c.media_type
	,c.unit_type
	,c.market_product_type_id
	
