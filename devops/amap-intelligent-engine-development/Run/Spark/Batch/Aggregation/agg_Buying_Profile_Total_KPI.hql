SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE Buying_Profile_Total_KPI PARTITION (partition_date = {{ params.ENDDATE }})
SELECT DISTINCT 
	c.advertiser_id
	,c.advertiser_name
	,c.brand_name
	,c.brand_id
	,c.industry
	,c.commercial_audience AS audience
	,round(AVG(c.cp_media_type) OVER (PARTITION BY c.advertiser_id ,c.brand_name,c.commercial_audience),2) AS cp_total_audience
	,round(AVG(c.desired_avg_budget_daily) OVER (PARTITION BY c.advertiser_id,c.brand_name, c.commercial_audience),2) AS avg_daily_budget
	,round(AVG(c.avg_lines) OVER (PARTITION BY c.advertiser_id,c.brand_name, c.commercial_audience),2) AS avg_lines
FROM (
SELECT 
	a.advertiser_id
	,a.advertiser_name
	,a.brand_name
	,a.brand_id
	,a.industry
	,b.commercial_audience
	,a.cp_media_type
	,a.desired_avg_budget_daily
	,a.avg_lines
	,a.discount
	,a.objective
FROM Buying_Profile_Media_KPI a
JOIN (
	select * from (
	SELECT advertiser_id
		,advertiser_name
		,brand_name
		,brand_id
		,commercial_audience
		,ROW_NUMBER() over (PARTITION by advertiser_id,brand_id ORDER BY total_price DESC) AS rnk
	FROM TRF_Advertiser_Audience
	WHERE partition_date = {{ params.ENDDATE }}
	) x where rnk=1 ) b ON (
		a.advertiser_id = b.advertiser_id
		AND coalesce(nullif(a.brand_id,''),' ') = coalesce(nullif(b.brand_id,''),' ')
		)
WHERE a.partition_date = {{ params.ENDDATE }} ) c;

