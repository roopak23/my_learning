SELECT DISTINCT
    advertiser_id,
    advertiser_name,
	brand_name,
	brand_id,
	coalesce(industry,'') industry,
    audience,
	cp_total_audience,
    avg_daily_budget,
	avg_lines
--    discount,
 --   objective
FROM Buying_Profile_Total_KPI
WHERE partition_date = {{ params.ENDDATE }}
