SELECT
    advertiser_id,
    advertiser_name,
	brand_name,
	brand_id,
    catalog_level,
	industry,
    record_type,
	media_type,
    length,
	display_name,
	perc_value
FROM Buying_Profile_Product_KPI
WHERE partition_date = {{ params.ENDDATE }}

