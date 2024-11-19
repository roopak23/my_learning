INSERT INTO api_inventorycheck_history
SELECT 
	`date`,
	adserver_id,
	adserver_adslot_id,
	adserver_adslot_name,
	audience_name,
	metric,
	state,
	city,
	event,
	pod_position,
	video_position,
	future_capacity,
	booked,
	reserved,
	missing_forecast,
	missing_segment,
	overwriting,
	percentage_of_overwriting,
	overwritten_impressions,
	overwriting_reason,
	use_overwrite,
	Updated_By
FROM data_activation.api_inventorycheck WHERE `date` <= DATE_SUB(SYSDATE(), INTERVAL 1 DAY);


DELETE FROM api_inventorycheck WHERE `date` <= DATE_SUB(SYSDATE(), INTERVAL 1 DAY);

CREATE TABLE IF NOT EXISTS override_update_history_purge
(
	`id` int ,
	`date` datetime,
	`adserver_id` varchar(50) DEFAULT NULL,
	`adserver_adslot_id` varchar(50),
	`adserver_adslot_name` varchar(255) DEFAULT NULL,
	`audience_name` varchar(255) DEFAULT NULL,
	`metric` varchar(20) DEFAULT NULL,
	`state` varchar(150),
	`city` varchar(150),
	`event` varchar(150),
	`pod_position` varchar(50) ,
	`video_position` varchar(100) ,
	`future_capacity` int DEFAULT 0,
	`booked` int DEFAULT 0,
	`reserved` int DEFAULT 0,
	`missing_forecast` varchar(255) DEFAULT 'N',
	`missing_segment` varchar(255) DEFAULT 'N',
	`overwriting` varchar(255) DEFAULT NULL,
	`percentage_of_overwriting` varchar(255) DEFAULT NULL,
	`overwritten_impressions` int DEFAULT NULL,
	`overwriting_reason` varchar(255) DEFAULT NULL,
	`use_overwrite` varchar(255) DEFAULT NULL,
    `update_date_time` Datetime,
    `updated_by` varchar(60),
    `active_record_status` varchar(60),
	`overwritten_expiry_date` datetime
);

INSERT INTO override_update_history_purge 
SELECT * 
FROM override_update_history 
WHERE update_date_time < (
select min(h.update_date_time) from (SELECT update_date_time 
        FROM override_update_history 
        GROUP BY update_date_time 
        ORDER BY update_date_time DESC 
        LIMIT 5 ) h
);
 
WITH RankedRecords AS (
    SELECT 
        h.update_date_time,
        ROW_NUMBER() OVER (ORDER BY h.update_date_time DESC) AS row_num
    FROM (SELECT DISTINCT update_date_time FROM override_update_history) h
)
DELETE 
FROM override_update_history 
WHERE update_date_time < (
    SELECT update_date_time 
    FROM RankedRecords 
    WHERE row_num = 5
);
