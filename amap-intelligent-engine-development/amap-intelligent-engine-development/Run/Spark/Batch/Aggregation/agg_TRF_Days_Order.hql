SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_Days_Order PARTITION (partition_date = {{ params.ENDDATE }})
SELECT a.advertiser_id
	,a.advertiser_name
	,b.brand_name
	,b.brand_id
	,a.industry
	,b.market_order_id
	,CASE WHEN upper(trim(c.adserver_type)) = 'GADS' THEN d.total_price ELSE b.total_price END AS budget_order
	,datediff(cast(from_unixtime(b.end_date div 1000, 'yyyy-MM-dd') as date), cast(from_unixtime(b.start_date div 1000, 'yyyy-MM-dd') as date)) AS count_days
FROM (
	SELECT DISTINCT advertiser_id
		,advertiser_name
		,brand_id
		,brand_name
		,industry
	FROM trf_advertiser
	WHERE partition_date = {{ params.ENDDATE }}
	) a
INNER JOIN STG_SA_Market_Order b ON a.advertiser_id = b.advertiser_id AND coalesce(nullif(a.brand_id,''),' ') = coalesce(nullif(b.brand_id,''),' ')
INNER JOIN STG_SA_Tech_Order d ON b.market_order_id = d.market_order_id
INNER JOIN STG_SA_Ad_Ops_System c ON d.system_id = c.adserver_id
WHERE b.partition_date = {{ params.ENDDATE }} AND
      c.partition_date = {{ params.ENDDATE }} AND
      d.partition_date = {{ params.ENDDATE }};
