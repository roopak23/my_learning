SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_Advertiser_Audience partition(partition_date = {{ params.ENDDATE }})
SELECT a.advertiser_id                  --> PK
	,a.brand_id                           --> PK
	,a.advertiser_name
	,a.brand_name
	,b.commercial_audience                --> PK
	,SUM(CASE WHEN upper(trim(c.adserver_type)) = 'GADS' THEN d.total_price ELSE b.total_price END) as total_price
FROM (SELECT DISTINCT advertiser_id , advertiser_name , brand_name, brand_id from TRF_advertiser WHERE partition_date = {{ params.ENDDATE }}) a
INNER JOIN STG_SA_Market_Order b ON a.advertiser_id = b.advertiser_id AND coalesce(nullif(a.brand_id,''),' ') = coalesce(nullif(b.brand_id,''),' ')
INNER JOIN STG_SA_Tech_Order d ON b.market_order_id = d.market_order_id
INNER JOIN STG_SA_Ad_Ops_System c ON d.system_id = c.adserver_id
Where b.partition_date = {{ params.ENDDATE }} AND c.partition_date = {{ params.ENDDATE }} AND d.partition_date = {{ params.ENDDATE }}
group by a.advertiser_id
	,a.advertiser_name
	,a.brand_id
	,a.brand_name
	,b.commercial_audience;
