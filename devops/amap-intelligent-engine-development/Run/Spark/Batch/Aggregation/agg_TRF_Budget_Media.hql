SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_Budget_Media PARTITION (partition_date = {{ params.ENDDATE }})
SELECT
	 a.advertiser_id AS advertiser_id                                       --> PK
	,a.advertiser_name AS advertiser_name
	,a.brand_name AS brand_name
	,a.brand_id AS brand_id                                                 --> PK
	,a.industry AS industry
	,b.media_type AS media_type                                             --> PK
	,b.unit_type AS unit_of_measure                                         --> PK
	,round(b.unit_price / b.unit_type_frequency,2) AS cp_media_type
 	,round(d.desired_avg_budget_daily,2) AS desired_avg_budget_daily
 	,c.avg_lines
	,b.selling_type AS selling_type                                         --> PK
	,b.market_product_type_id                                               --> PK
 	,e.media_perc
 	,round(f.discount,2) as discount
 	,g.objective                                                            --> PK
FROM (SELECT  DISTINCT market_product_type_id,advertiser_id, advertiser_name ,industry ,media_type ,brand_name,brand_id, partition_date  --> industry and  advertiser_name are at adertiser_id level
	    FROM  trf_days_line_avg
	    WHERE partition_date=  {{ params.ENDDATE }}) a
INNER JOIN trf_advertiser_metric b ON a.advertiser_id = b.advertiser_id
	AND coalesce(nullif(a.media_type,''),' ') = coalesce(nullif(b.media_type,''),' ')
--	AND coalesce(nullif(a.unit_type,''),' ') = coalesce(nullif(b.unit_type,''),' ')
	AND coalesce(nullif(a.market_product_type_id,''),' ') = coalesce(nullif(b.market_product_type_id,''),' ')
	AND coalesce(nullif(a.brand_id,''),' ') = coalesce(nullif(b.brand_id,''),' ')
INNER JOIN (
	SELECT advertiser_id
	,advertiser_name
	,brand_name
	, brand_id
	,media_type
	-- ,unit_type
	,market_product_type_id
	,avg(count_lines) AS avg_lines
FROM trf_line_count
WHERE partition_date = {{ params.ENDDATE }}
GROUP BY advertiser_id, advertiser_name, brand_name, brand_id,
media_type, market_product_type_id)C ON a.advertiser_id = c.advertiser_id
	AND coalesce(nullif(a.media_type,''),' ') = coalesce(nullif(c.media_type,''),' ')
	AND coalesce(nullif(b.market_product_type_id,''),' ') = coalesce(nullif(c.market_product_type_id,''),' ')
	AND coalesce(nullif(b.brand_id,''),' ') = coalesce(nullif(c.brand_id,''),' ')
INNER JOIN (
	SELECT advertiser_id
	,advertiser_name
	,brand_name
	,brand_id
	,media_type
--	,unit_type
	,market_product_type_id
	,AVG(daily_budget_line) as desired_avg_budget_daily
FROM trf_days_line_avg
WHERE partition_date = {{ params.ENDDATE }}
GROUP BY advertiser_id, advertiser_name, brand_name, brand_id,
      media_type,market_product_type_id ) d ON a.advertiser_id = d.advertiser_id
	AND coalesce(nullif(a.media_type,''),' ') = coalesce(nullif(d.media_type,''),' ')
	-- and coalesce(nullif(b.unit_type,''),' ') = coalesce(nullif(d.unit_type,''),' ')
	and coalesce(nullif(b.market_product_type_id,''),' ') = coalesce(nullif(d.market_product_type_id,''),' ')
	AND coalesce(nullif(c.brand_id,''),' ') = coalesce(nullif(d.brand_id,''),' ')
INNER JOIN (
	SELECT advertiser_id
	,brand_id
	,media_type
	-- ,unit_type
	,market_product_type_id
	,avg(discount) as discount
FROM trf_days_line_avg
WHERE partition_date = {{ params.ENDDATE }}
group by advertiser_id, brand_id, media_type,market_product_type_id
 ) f
on f.advertiser_id = a.advertiser_id and
coalesce(nullif(f.media_type,''),' ') = coalesce(nullif(a.media_type,''),' ')
--  and coalesce(nullif(b.unit_type,''),' ') = coalesce(nullif(f.unit_type,''),' ')
and coalesce(nullif(b.market_product_type_id,''),' ') = coalesce(nullif(f.market_product_type_id,''),' ')
and coalesce(nullif(f.brand_id,''),' ') = coalesce(nullif(a.brand_id,''),' ')
inner join
		(
		select advertiser_id, brand_id, media_type,objective, market_product_type_id, rnk from (
		select advertiser_id, brand_id, media_type,objective, unit_type,market_product_type_id, total_price ,
		ROW_NUMBER() over(partition by advertiser_id, brand_id, media_type, market_product_type_id order by total_price desc ) as rnk
		from trf_days_line_avg where
		partition_date= {{ params.ENDDATE }}) as p
		where rnk=1
		)
		g
on g.advertiser_id =a.advertiser_id
and coalesce(nullif(g.media_type,''),' ') = coalesce(nullif(a.media_type,''),' ')
--  and coalesce(nullif(b.unit_type,''),' ') = coalesce(nullif(g.unit_type,''),' ')
and coalesce(nullif(b.market_product_type_id,''),' ') = coalesce(nullif(g.market_product_type_id,''),' ')
and coalesce(nullif(g.brand_id,''),' ') = coalesce(nullif(a.brand_id,''),' ')
INNER JOIN (
	SELECT  distinct  --> null( doule check)
	t1.advertiser_id
	,t1.brand_id
	,t1.media_type
	-- ,t1.unit_of_measure
	,t1.market_product_type_id
	,ROUND(t1.med_budget/t1.adv_budget * 100) as media_perc
FROM (SELECT distinct
	t2.advertiser_id
	,t2.brand_id
	,t2.media_type
	,t2.market_product_type_id
	,round(sum(t2.total_price) over (PARTITION by t2.media_type,t2.advertiser_id, t2.brand_id, market_product_type_id),2) as med_budget,
	round(sum(t2.total_price) over (PARTITION by t2.advertiser_id, t2.brand_id),2) as adv_budget
	FROM
		( select n.advertiser_id
	,n.brand_id
	,n.mediatype AS media_type
--	,n.unit_of_measure
	,n.total_price
	,n.market_product_type market_product_type_id
	FROM TRF_market_order_line_details N
	WHERE n.partition_date = {{ params.ENDDATE }}) t2)
	t1 ) e
  ON a.advertiser_id = e.advertiser_id
  -- and coalesce(nullif(b.unit_type,''),' ') = coalesce(nullif(e.unit_of_measure,''),' ')
	 and coalesce(nullif(b.media_type,''),' ') = coalesce(nullif(e.media_type,''),' ')
	 and coalesce(nullif(b.market_product_type_id,''),' ') = coalesce(nullif(e.market_product_type_id,''),' ')
	 and coalesce(nullif(e.brand_id,''),' ') = coalesce(nullif(a.brand_id,''),' ')
WHERE a.partition_date = {{ params.ENDDATE }} AND b.partition_date = {{ params.ENDDATE }}
