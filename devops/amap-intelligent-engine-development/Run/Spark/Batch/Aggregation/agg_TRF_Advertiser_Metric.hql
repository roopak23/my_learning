SET hive.auto.convert.join = FALSE;

INSERT
    OVERWRITE TABLE TRF_Advertiser_Metric PARTITION (partition_date = {{params.ENDDATE}})
select
    f.advertiser_id AS advertiser_id,                   --> PK
    f.advertiser_name AS advertiser_name,
    f.brand_name AS brand_name,
    f.brand_id AS brand_id,                             --> PK
    f.media_type AS media_type,                         --> PK
    f.unit_type_first AS unit_type,                     --> PK
    f.unit_type_frequency AS unit_type_frequency,
    round(SUM(f.total_price), 2) AS total_price,
    round(SUM(f.unit_price), 2) AS unit_price,
    f.selling_type_first selling_type,                  --> PK
    f.market_product_type_id                            --> PK
from
    (
        SELECT
            d.advertiser_id,
            d.brand_name,
            d.brand_id,
            ta.advertiser_name,
            d.mediatype AS media_type,
            first_value(d.unit_of_measure) over(
                partition by d.advertiser_id,
                d.brand_id,
                d.mediatype,
                d.market_product_type,
                d.partition_date
                order by
                    case
                        when d.unit_of_measure is not null then 1
                        else 0
                    end desc,
                    d.total_price desc,d.market_order_line_details_id desc
            )  AS unit_type_first,
            round(d.total_price, 2) as total_price,
            round(d.unit_price, 2) as unit_price,
            d.market_product_type AS market_product_type_id,
            d.format AS format_id,
            d.partition_date,
            count(1) over(
                partition by d.advertiser_id,
                d.brand_id,
                d.mediatype,
                d.market_product_type,
                d.partition_date
            ) unit_type_frequency,
            --select 1st existing seelong type valuefor the mold with highest price
            first_value(d.unit_of_measure) over(
                partition by d.advertiser_id,
                d.brand_id,
                d.mediatype,
                d.market_product_type,
                d.partition_date
                order by
                    case
                        when d.unit_of_measure is not null then 1
                        else 0
                    end desc,
                    d.total_price desc, d.market_order_line_details_id desc
            )  AS selling_type_first
        FROM
             TRF_market_order_line_details d
            inner join (
                select
                    DISTINCT advertiser_id, brand_id, advertiser_name, partition_date
                from
                    trf_advertiser
                where
                    partition_date = {{params.ENDDATE}}
            ) ta on ta.advertiser_id = d.advertiser_id AND coalesce(nullif(ta.brand_id,''),' ') = coalesce(nullif(d.brand_id,''),' ')
            WHERE
            d.partition_date = {{params.ENDDATE}}
    ) f
group by
    f.advertiser_id,
    f.advertiser_name,
    f.brand_name,
    f.brand_id,
    f.media_type,
    f.unit_type_first,
    f.unit_type_frequency,
    f.selling_type_first,
    f.market_product_type_id
