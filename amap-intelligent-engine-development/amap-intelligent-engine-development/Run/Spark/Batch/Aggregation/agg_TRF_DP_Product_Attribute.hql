SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_DP_Product_Attribute PARTITION (partition_date = {{ params.ENDDATE }})
SELECT
    sys_datasource,
    sys_load_id,
    sys_created_on,
    product_id,
    attribute_name,
    REPLACE(REPLACE(attribute_value, " ", ""), "_", "") AS attribute_value
FROM STG_DP_Product_Attribute
WHERE partition_date = {{ params.ENDDATE }};