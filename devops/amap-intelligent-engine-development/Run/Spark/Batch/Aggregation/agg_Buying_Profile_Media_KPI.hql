SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE Buying_Profile_Media_KPI PARTITION (partition_date = {{ params.ENDDATE }})
SELECT advertiser_id                                                                --> PK
    ,advertiser_name
    ,brand_name
    ,brand_id                                                                       --> PK
    ,industry
    ,media_type                                                                     --> PK
    ,unit_of_measure                                                                --> PK
    ,round((desired_avg_budget_daily/cp_media_type),0) as desired_metric_daily_avg
    ,cp_media_type
    ,desired_avg_budget_daily
    ,avg_lines
    ,selling_type                                                                   --> PK
    ,market_product_type_id                                                         --> PK
    ,media_perc
    ,discount as discount
    ,objective as objective                                                         --> PK
FROM TRF_Budget_Media
WHERE partition_date = {{ params.ENDDATE }}
