Delete from Suggested_Product;
INSERT into Suggested_Product
SELECT 
concat(sp.dm_id,'_P',ROW_NUMBER() over(partition BY sp.dm_id  order by bpmk.advertiser_id, bpmk.brand_id, pr.format_id,bpmk.market_product_type_id,bpmk.media_type,bpmk.unit_of_measure)) dm_id,
sp.dm_id propsal_id
,pr.simulation_id
,bpmk.brand_id
,bpmk.media_type
,pr.format_id
,coalesce(spi.price_item_id,'')
,null as quantity
,bpmk.unit_of_measure as unit_of_measure_media_type
,spi.price_per_unit as unit_net_price
,spi.price_list as list_price
,null as total_net_price
,null as discount
,spi.spot_length as length
,pr.score
,COALESCE(soi.inventory_available, invc.sum_inventory_available)
,ci.commercial_audience
,ci.objective
,round(avg(bpmk.avg_lines) over (partition by bpmk.advertiser_id, bpmk.brand_id, bpmk.media_type),2) as avg_lines
,pr.gads_bidding_strategy
,null as  ttd_kpi
,null as  ttd_target_value
,null as base_bid
,null as max_bid
,bpmk.media_perc
, case
when aos.adserver_type in ('GAM') then 0
else 1
end as third_party_product
,ci.adserver_id  as adops_system_id
,avg(bpmk.desired_avg_budget_daily) OVER (PARTITION BY bpmk.advertiser_id, bpmk.brand_id) as avg_daily_budget
,bpmk.market_product_type_id
FROM data_activation.Suggested_Proposal sp inner join data_activation.ML_product_recommendation pr
on sp.simulation_id = pr.simulation_id
and sp.advertiser_id = pr.advertiser_id
and COALESCE(NULLIF(sp.brand_id,''),' ') = COALESCE(NULLIF(pr.brand_id,''),' ')
left  join data_activation.STG_SA_CatalogItem ci
on pr.format_id = ci.catalog_item_id
left  join data_activation.STG_SA_Price_Item spi
on ci.catalog_item_id = spi.catalog_item_id
inner join data_activation.Buying_Profile_Media_KPI bpmk
on pr.advertiser_id = bpmk.advertiser_id
and COALESCE(NULLIF(pr.brand_id,''),' ') = COALESCE(NULLIF(bpmk.brand_id,''),' ')
left join
(select adserver_id,
catalog_item_name,
catalog_item_id,
sum(future_capacity)-(sum(booked)+sum(reserved)) as inventory_available
from data_activation.so_inventory where `date` between date_add(current_date(),interval 1 day) and date_add(current_date(),interval 31 day)
group by adserver_id,
catalog_item_name, catalog_item_id) soi
on ci.catalog_item_id = soi.catalog_item_id
left join data_activation.stg_sa_ad_ops_system aos
on ci.adserver_id = aos.adserver_id
left join 
(select
catalog_item_id,
SUM(available) AS sum_inventory_available
from data_activation.trf_invfuture_commercials where `date` between date_add(current_date(),interval 1 day) and date_add(current_date(),interval 31 day)
group by catalog_item_id) invc
on ci.catalog_item_id = invc.catalog_item_id