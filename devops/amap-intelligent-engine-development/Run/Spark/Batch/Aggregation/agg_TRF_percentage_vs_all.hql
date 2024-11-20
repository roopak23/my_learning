DROP TABLE IF EXISTS TRF_percentage_vs_all_temp;

CREATE TABLE TRF_percentage_vs_all_temp AS
SELECT DISTINCT
    a.`adserver_id`,
    b.`adserver_adslot_id`,
    b.`adserver_target_remote_id`,
    b.`adserver_target_name`,
    CASE WHEN A.metric_quantity == 0
    THEN 0
    ELSE round(B.metric_quantity/A.metric_quantity, 10)
    END ratio
FROM(
    SELECT
        `adserver_adslot_id`,
        `adserver_target_remote_id`,
        `adserver_target_name`,
        `metric_quantity`,
        `metric`,
        `adserver_id`
    FROM TRF_perf_gathering_metric
	WHERE adserver_target_remote_id = 'all'
		AND adserver_target_name = 'all'
		AND partition_date = {{ params.ENDDATE }}) A
	INNER JOIN TRF_perf_gathering_metric B ON A.adserver_adslot_id = B.adserver_adslot_id
		AND A.adserver_id = B.adserver_id
		AND A.metric = B.Metric
	WHERE partition_date = {{ params.ENDDATE }}
		AND UPPER(TRIM(A.metric)) = "IMPRESSION";

MERGE INTO TRF_percentage_vs_all X
USING TRF_percentage_vs_all_temp Y ON X.adserver_adslot_id = Y.adserver_adslot_id
    AND X.adserver_target_remote_id = Y.adserver_target_remote_id
WHEN MATCHED THEN UPDATE SET ratio = Y.ratio
WHEN NOT MATCHED THEN INSERT VALUES (Y.adserver_id, Y.adserver_adslot_id, Y.adserver_target_remote_id, Y.adserver_target_name, Y.ratio);

DROP TABLE IF EXISTS TRF_percentage_vs_all_temp;
