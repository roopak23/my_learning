DELETE FROM inventory;
INSERT INTO inventory 
SELECT DISTINCT
	a.`date`,
	b.adserver_id,
	a.adserver_adslot_id,
	'',
	a.metric,
	a.`state`,
	a.city,
	a.event,
	a.pod_position,
	a.video_position,
	a.future_capacity,
	b.booked
FROM ML_InvForecastingOutputSegmentDistributed a
INNER JOIN (Select adserver_id, adserver_adslot_id, sum(booked) as booked,`date` from STG_Adserver_InvFuture GROUP BY adserver_id, adserver_adslot_id,`date`)b 
ON a.adserver_adslot_id = b.adserver_adslot_id
AND a.adserver_id = b.adserver_id
AND a.`date` = b.`date`;
