SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_Days_Order_Avg PARTITION (partition_date = {{ params.ENDDATE }})
SELECT advertiser_id  
    ,advertiser_name
    ,brand_name
    ,brand_id
    ,industry
    ,market_order_id                                --> PK
    ,budget_order
    ,count_days
    ,count(*) over (partition by advertiser_id,brand_id,market_order_id) AS count_lines
    ,(budget_order/count_days) as daily_budget
FROM TRF_Days_Order
WHERE partition_date = {{ params.ENDDATE }}