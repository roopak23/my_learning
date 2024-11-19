CREATE PROCEDURE IF NOT EXISTS GetHistoryData(IN update_datetime_filter  DATETIME, IN start_index INTEGER, IN page_size INTEGER)
BEGIN
    SET SESSION MAX_EXECUTION_TIME = 20000;
    WITH ranked_data AS (
    SELECT 
        o.update_date_time,
        s.level1,
        s.level2,
        s.level3,
        s.level4,
        s.level5,
        o.event,
        o.updated_by, 
        o.overwriting_reason ,
        DENSE_RANK() OVER (
            ORDER BY o.update_date_time DESC, o.updated_by
        ) AS rank_num,
        SUM(o.future_capacity) AS future_capacity,
        SUM(o.overwritten_impressions) AS overwritten_impressions
    FROM 
        override_update_history o /*force index (override_update_history_update_date_time_IDX)*/
        join 
        STG_SA_Ad_Slot s /*force index (STG_SA_Ad_Slot_adserver_id_status_IDX) */
        on (TRIM(o.adserver_adslot_id) = TRIM(s.adserver_adslot_id ))
    WHERE	(o.overwritten_impressions+0) > 0
    	AND TRIM(s.status) = "ACTIVE" 
    	AND date(o.update_date_time) = date(update_datetime_filter)
    GROUP BY 
        o.update_date_time,s.Level1,s.level2,s.level3,s.level4,s.level5,o.event,o.updated_by,o.overwriting_reason
    ORDER BY rank_num
),
latest AS (
    SELECT 
        rank_num,
        level1,
        level2,
        level3,
        level4,
        level5,
        event,
        updated_by AS latest_updated_by,
        update_date_time AS latest_update_date_time,
        future_capacity AS latest_future_capacity,
        overwritten_impressions AS latest_overwritten_impressions,
        overwriting_reason AS latest_overwriting_reason
    FROM 
        ranked_data
),
oldest AS (
    SELECT 
        (rank_num - 1) AS rank_num,
        level1,
        level2,
        level3,
        level4,
        level5,
        event,
        updated_by AS old_updated_by,
        update_date_time AS old_update_date_time,
        future_capacity AS old_future_capacity,
        overwritten_impressions AS old_overwritten_impressions,
        overwriting_reason AS old_overwriting_reason
    FROM 
        ranked_data
    WHERE 
        rank_num > 1
),
TMP AS 
(
SELECT 
	l.level1,
	l.level2,
	l.level3,
	l.level4,
	l.level5,
	l.event,
    l.latest_update_date_time ,
    l.latest_future_capacity,
    l.latest_overwritten_impressions ,
    l.latest_updated_by,
    l.latest_overwriting_reason,
    o.old_update_date_time,
    o.old_future_capacity,
    o.old_overwritten_impressions,
    o.old_updated_by,
    o.old_overwriting_reason
FROM 
    latest l
LEFT JOIN 
    oldest o ON (l.rank_num)+0 = (o.rank_num)+0
    and (l.level1 = o.level1 OR (l.level1 IS NULL AND o.level1 IS NULL)) 
    and (l.level2 = o.level2 OR (l.level2 IS NULL AND o.level2 IS NULL)) 
    and (l.level3 = o.level3 OR (l.level3 IS NULL AND o.level3 IS NULL)) 
    and (l.level4 = o.level4 OR (l.level4 IS NULL AND o.level4 IS NULL)) 
    and (l.level5 = o.level5 OR (l.level5 IS NULL AND o.level5 IS NULL))
    and (l.event = o.event OR (l.event IS NULL AND o.event IS NULL)) 
ORDER BY 
    l.level1,l.level2,l.level3,l.level4,l.level5,l.event,l.rank_num
)
SELECT 
	A.level1,
	A.level2,
	A.level3,
	A.level4,
	A.level5,
	A.event,
    A.latest_update_date_time as latest_overwritten_impressions_update_date_time,
    A.latest_future_capacity,
    A.latest_overwritten_impressions as latest_overwritten_impressions,
    A.latest_updated_by as latest_overwritten_impressions_updated_by,
    A.latest_overwriting_reason as latest_overwriting_reason,
    A.old_update_date_time as old_overwritten_impressions_update_date_time,
    A.old_future_capacity as old_future_capacity,
    A.old_overwritten_impressions as old_overwritten_impressions,
    A.old_updated_by as old_overwritten_impressions_updated_by,
    A.old_overwriting_reason as old_overwriting_reason,
	B.record_count
FROM TMP A JOIN (SELECT COUNT(*) as record_count FROM TMP) B ON 1 = 1 LIMIT page_size  OFFSET start_index;
SET SESSION MAX_EXECUTION_TIME = 0;
END;