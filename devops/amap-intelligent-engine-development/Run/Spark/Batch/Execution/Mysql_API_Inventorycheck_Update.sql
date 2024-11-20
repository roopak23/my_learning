INSERT INTO api_inventorycheck(
	date,
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
SELECT
	K.`date`,
	K.adserver_id,
	K.adserver_adslot_id,
	K.adserver_adslot_name,
	'' AS audience_name,
	K.metric,
	K.state,
	K.city,
	K.event,
	K.pod_position,
	K.video_position,
	K.future_capacity,
	K.booked,
	'N' missing_forecast FROM
(SELECT
    S.`date`,
    S.adserver_id,
    S.adserver_adslot_id,
    S.adserver_adslot_name,
    S.metric,
	S.state,
	S.city,
	S.event,
	S.pod_position,
	S.video_position,
	S.future_capacity,
    ROUND((S.future_capacity/J.GT_future_cap) * S.booked,0) as booked
FROM inventory S JOIN
(
SELECT adserver_adslot_id,sum(future_capacity) as GT_future_cap,`date`
FROM inventory
group by adserver_adslot_id,`date`
) J ON 
S.adserver_adslot_id  = J.adserver_adslot_id and S.`date` = J.`date`
) K
LEFT JOIN api_inventorycheck T ON K.adserver_adslot_id = T.adserver_adslot_id 
	AND K.adserver_id = T.adserver_id
	AND K.`date` = T.`date`
	AND K.adserver_adslot_id = T.adserver_adslot_id
	AND K.state = T.state
	AND K.city = T.city
	AND K.event = T.event
	AND K.pod_position = T.pod_position
	AND K.video_position = T.video_position
ON DUPLICATE KEY UPDATE future_capacity = K.future_capacity,
	missing_forecast ='N',
	Updated_By = Null,
	booked = K.booked ;

UPDATE api_inventorycheck 
SET use_overwrite = 'N'
where DATE(overwritten_expiry_date) <= CURRENT_DATE();
