SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_Days_Line_Avg PARTITION (partition_date = {{ params.ENDDATE }})
SELECT advertiser_id
    ,advertiser_name
    ,brand_name
    ,brand_id
    ,industry
    ,market_order_line_details_id   --> PK
    ,media_type
    ,unit_type
    ,total_price
    ,count_days
    ,(total_price/count_days) as daily_budget_line
    ,market_product_type_id
    ,discount
    ,objective
FROM TRF_Days_Line
WHERE partition_date = {{ params.ENDDATE }}
