SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_Advertiser_Budget PARTITION (partition_date = {{ params.ENDDATE }})
SELECT DISTINCT a.advertiser_id
	,a.advertiser_name
	,a.brand_name
	,a.brand_id
	,a.media_type 
	,SUM (a.budget) OVER (PARTITION BY a.advertiser_id,a.brand_id,a.media_type)
FROM (
	SELECT  
	advertiser_id,
	advertiser_name,
	market_order_line_details_id,
	media_type,
	brand_name,
	brand_id,
	budget 
	FROM 
	trf_advertiser_spec
	WHERE partition_date = {{ params.ENDDATE }}) a;
 

