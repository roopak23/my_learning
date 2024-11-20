TRUNCATE TABLE FR_monthy_distribution;

INSERT INTO FR_monthy_distribution	
SELECT
    month,
    catalog_item_name,
    catalog_full_path,
    adserver_adslot_id,
    adserver_adslot_name,
    GREATEST(COALESCE(initial_distribution + CASE WHEN row_num <= remainder THEN 1 ELSE 0 END, 0), 0) AS adjusted_distribution
FROM (
    SELECT
        t1.month,
        t1.catalog_item_name,
        t1.catalog_full_path,
        t2.adserver_adslot_id,
        t2.adserver_adslot_name,
        t2.monthly_booking,
        t1.total_sum,
        FLOOR(GREATEST(t2.monthly_booking * 100 / t1.total_sum, 0)) AS initial_distribution,
        ROW_NUMBER() OVER (PARTITION BY t1.month, t1.catalog_item_name ORDER BY t2.adserver_adslot_id) AS row_num,
        GREATEST(100 - SUM(FLOOR(GREATEST(t2.monthly_booking * 100 / t1.total_sum, 0))) 
                 OVER (PARTITION BY t1.month, t1.catalog_item_name), 0) AS remainder 
    FROM (
        SELECT
            month,
            catalog_item_name,
            catalog_full_path,
            SUM(GREATEST(monthly_booking, 0)) AS total_sum
        FROM FR_monthy_grouping
        GROUP BY month, catalog_item_name, catalog_full_path
    ) t1
    JOIN FR_monthy_grouping t2
    ON t1.month = t2.month AND t1.catalog_item_name = t2.catalog_item_name
) t
ORDER BY month, catalog_item_name, adserver_adslot_id;
