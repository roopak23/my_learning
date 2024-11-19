SELECT
    advertiser_id ,
    advertiser_name ,
    brand_name ,
    brand_id ,
    industry ,
    media_type ,
    coalesce(unit_of_measure,''),
    desired_metric_daily_avg ,
    cp_media_type ,
    desired_avg_budget_daily ,
    avg_lines ,
    coalesce(selling_type,'') selling_type,
    media_perc,
    coalesce(market_product_type_id,'') market_product_type_id,
    discount,
    objective
 FROM Buying_Profile_Media_KPI
 WHERE partition_date = {{ params.ENDDATE }}



