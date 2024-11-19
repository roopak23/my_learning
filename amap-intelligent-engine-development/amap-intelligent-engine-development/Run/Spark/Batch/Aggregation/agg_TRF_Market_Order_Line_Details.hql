INSERT OVERWRITE TABLE TRF_Market_Order_Line_Details PARTITION (partition_date = {{ params.ENDDATE }})
SELECT 
a.market_order_line_details_id,                                                 --> PK
a.name,
a.ad_server_name,
a.ad_server_type,
a.breadcrumb,
a.campaign_objective,
b.commercial_audience,
a.day_part,
a.discount_ds,
a.discount_ssp,
cast(from_unixtime(a.end_date div 1000, 'yyyy-MM-dd') as date) as end_date,
a.format,
a.format_name,
a.length,
a.market_order_id,
a.market_order_line,
a.market_product_type,
a.mediatype,
ta.advertiser_id,
ta.advertiser_name,
coalesce(nullif(ta.industry,''),'unknown') industry,
a.priceitem,
a.quantity,
cast(from_unixtime(a.start_date div 1000, 'yyyy-MM-dd') as date) as start_date,
a.unit_net_price,
a.unit_price,
a.total_net_price,
a.unit_of_measure,
a.frequency_capping,
a.frequency_capping_quantity,
a.status,
CASE WHEN upper(trim(a.ad_server_type)) = 'GADS' THEN c.total_price ELSE a.total_price END AS total_price,
a.carrier_targeting,
a.custom_targeting,
a.daypart_targeting,
a.device_targeting,
a.geo_targeting,
a.os_targeting,
a.time_slot_targeting,
a.weekpart_targeting,
cast(from_unixtime(a.recent_view div 1000, 'yyyy-MM-dd') as date) as recent_view,
cast(from_unixtime(a.recent_change div 1000, 'yyyy-MM-dd') as date) as recent_change,
a.gads_bidding_strategy,
b.brand_id,
b.brand_name
FROM STG_sa_market_order_line_details a JOIN STG_sa_market_order b on
a.market_order_id = b.market_order_id
JOIN ( select DISTINCT advertiser_id, advertiser_name, industry, partition_date  FROM trf_advertiser where partition_date = {{ params.ENDDATE }})  ta ON
b.advertiser_id = ta.advertiser_id
INNER JOIN STG_SA_Tech_Order c ON b.market_order_id = c.market_order_id
WHERE a.partition_date = {{ params.ENDDATE }} and b.partition_date = {{ params.ENDDATE }} 
      and ta.partition_date = {{ params.ENDDATE }} and c.partition_date = {{ params.ENDDATE }}
      and upper(trim(a.ad_server_type)) != 'GADS'

