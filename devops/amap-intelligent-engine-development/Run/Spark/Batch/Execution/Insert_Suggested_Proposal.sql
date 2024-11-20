Delete from Suggested_Proposal;
Insert into Suggested_Proposal
SELECT
concat('DM','_A',pr.advertiser_id,'_S', ROW_NUMBER() OVER (PARTITION BY pr.advertiser_id ORDER BY pr.format_id,pr.simulation_id) ) dm_id,
pr.simulation_id
,pr.advertiser_id
,pr.brand_id
,bpmk.desired_avg_budget_daily as avg_daily_budget
,pr.start_date
,pr.end_date
,ci.commercial_audience as audience
,ci.objective
from data_activation.ML_product_recommendation pr JOIN
( SELECT advertiser_id, brand_id, avg(bpmk.desired_avg_budget_daily)  desired_avg_budget_daily
    FROM Buying_Profile_Media_KPI bpmk group by advertiser_id, brand_id) bpmk
 ON pr.brand_id = bpmk.brand_id AND pr.advertiser_id = bpmk.advertiser_id
 LEFT JOIN STG_SA_CatalogItem ci
 ON pr.format_id = ci.catalog_item_id;