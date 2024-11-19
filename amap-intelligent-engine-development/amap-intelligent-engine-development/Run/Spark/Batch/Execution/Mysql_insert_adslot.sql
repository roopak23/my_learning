INSERT IGNORE INTO api_inventorycheck(
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
	missing_forecast
    )
with Recursive TB_DateRange AS (
SELECT CONVERT(CURRENT_DATE ,CHAR) AS `date`
UNION ALL
SELECT DATE_ADD(`date`,INTERVAL 1 DAY)
FROM TB_DateRange WHERE date < CONVERT(DATE_ADD(CURRENT_DATE,INTERVAL 120 DAY), CHAR)
),
Adslots AS (
SELECT DISTINCT(A.adserver_adslot_id) FROM STG_SA_Ad_Slot A 
LEFT JOIN (SELECT DISTINCT(adserver_adslot_id) AS adserver_adslot_id FROM api_inventorycheck
where `date` = DATE_ADD(CURDATE(),INTERVAL 120 DAY)) B 
ON A.adserver_adslot_id  = B.adserver_adslot_id where B.adserver_adslot_id is null
)
,JOINED_TB AS 
(
SELECT A.adserver_adslot_id as new_ids,B.`date` FROM Adslots A  JOIN TB_DateRange B ON 1 = 1
)
,FUTURE AS 
(
SELECT DISTINCT(adserver_id) FROM STG_Adserver_InvFuture LIMIT 1
)
SELECT 
JOINED_TB.`date`	as `date`,
FUTURE.adserver_id	as adserver_id,
JOINED_TB.new_ids	as adserver_adslot_id,
''	as adserver_adslot_name,
''    as audience_name,
'IMPRESSION'	as metric,
''	as state,
''	as city,
''	as event,
''	as pod_position,
''	as video_position,
0	as future_capacity,
0	as booked,
'N' as missing_forecast
 FROM JOINED_TB JOIN FUTURE On 1 = 1
 
