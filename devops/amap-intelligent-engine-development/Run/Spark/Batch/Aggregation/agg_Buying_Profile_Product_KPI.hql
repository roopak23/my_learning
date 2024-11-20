SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE Buying_Profile_Product_KPI PARTITION (partition_date = {{ params.ENDDATE }})
SELECT advertiser_id
	,advertiser_name
	,brand_name
	,brand_id
	,catalog_level
	,industry
	,record_type
	,media_type
	,length
	,display_name
	,SUM(perc_price) AS perc_value
	,market_product_type_id
FROM TRF_Advertiser_Spec_Total
WHERE partition_date = {{ params.ENDDATE }}
GROUP BY advertiser_id
	,advertiser_name
	,brand_name,
	,brand_id
	,catalog_level
	,industry
	,record_type
	,media_type
	,length
	,display_name
	,market_product_type_id;


