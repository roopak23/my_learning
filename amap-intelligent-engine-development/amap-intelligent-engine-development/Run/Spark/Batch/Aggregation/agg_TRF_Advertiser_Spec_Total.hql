SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_Advertiser_Spec_Total PARTITION (partition_date = {{ params.ENDDATE }})
SELECT DISTINCT a.advertiser_id AS advertiser_id
	,a.advertiser_name AS advertiser_name
	,a.brand_name AS brand_name
	,a.brand_id AS brand_id
	,a.industry AS industry
	,a.market_order_line_details_id AS market_order_line_details_id
	,a.catalog_level AS catalog_level
	,a.record_type AS record_type
	,a.media_type AS media_type
	,a.length AS length
	,a.display_name AS display_name
	,a.budget / b.total_budget AS perc_price
	,a.market_product_type_id
FROM trf_advertiser_spec a
INNER JOIN trf_advertiser_budget b ON a.advertiser_id = b.advertiser_id
	AND a.media_type = b.media_type 
WHERE a.partition_date = {{ params.ENDDATE }} and b.partition_date = {{ params.ENDDATE }};
