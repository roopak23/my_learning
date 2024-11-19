SET hive.auto.convert.join= FALSE;


INSERT OVERWRITE TABLE TRF_INVENTORY PARTITION (partition_date = {{ params.ENDDATE }}) 
SELECT 
    d.`date`, 
	d.adserver_id, 
	d.adserver_adslot_id, 
	d.adserver_adslot_name,
    d.metric, 
	d.state ,  
	d.city , 
	d.event, 
	d.pod_position,  
	d.video_position,  
	SUM(greatest(d.future_capacity,0))  future_capacity, 
	SUM(greatest(d.booked,0)) booked
FROM (
	SELECT 
		c.`date`, 
		c.adserver_id, 
		c.adserver_adslot_id, 
		c.adserver_adslot_name,
		c.metric, 
		CASE WHEN c.future_capacity_rounded = 0 AND c.booked_rounded = 0 THEN '' 
		ELSE c.`state` END `state` , 
		CASE WHEN c.future_capacity_rounded = 0 AND c.booked_rounded = 0 THEN ''  
		ELSE c.city END city , 
		CASE WHEN c.future_capacity_rounded = 0 AND c.booked_rounded = 0 THEN '' 
		ELSE c.event END event, 
		CASE WHEN c.future_capacity_rounded = 0 AND c.booked_rounded = 0 THEN '' 
		ELSE c.pod_position END pod_position, 
		CASE WHEN c.future_capacity_rounded = 0 AND c.booked_rounded = 0 THEN '' 
		ELSE c.video_position END video_position,  
		future_capacity, 
		booked
	FROM (
		SELECT 
			b.`date`, 
			b.adserver_id, 
			b.adserver_adslot_id, 
			b.adserver_adslot_name,
			b.metric, 
			b.`state`, 
			b.city, 
			b.event, 
			b.pod_position, 
			b.video_position, 
			b.future_capacity, 
			b.booked,
			coalesce(greatest(round(b.future_capacity),0),0) future_capacity_rounded, 
			coalesce(greatest(round(b.booked),0),0) booked_rounded
		FROM (
			SELECT 
				coalesce(a.`date`,b.`date`) `date`, 
				coalesce(a.adserver_id,b.adserver_id) adserver_id, 
				coalesce(a.adserver_adslot_id,b.adserver_adslot_id) adserver_adslot_id, 
				'' adserver_adslot_name,
				coalesce(a.metric,b.metric) metric, 
				a.`state`, 
				a.city, 
				a.event, 
				CASE WHEN a.pod_position = 'U' THEN 'M' ELSE a.pod_position
				END 
				pod_position, 
				a.video_position, 
				coalesce(a.future_capacity,0) future_capacity, 
				CASE WHEN a.adserver_adslot_id IS NOT NULL and coalesce(future_capacity_adslot,0) <> 0  THEN
							coalesce(b.booked,0) * a.future_capacity/a.future_capacity_adslot
					WHEN a.adserver_adslot_id IS NOT NULL and coalesce(future_capacity_adslot,0) = 0  THEN
							coalesce(b.booked,0) /count(a.adserver_adslot_id) OVER (PARTITION BY a.`date`,a.adserver_adslot_id,a.adserver_id,a.metric)
					ELSE coalesce(b.booked,0)
				END booked
			FROM (SELECT a.* 
				FROM  ML_InvForecastingOutputSegmentDistributed a 
				WHERE a.partition_date = {{ params.ENDDATE }} ) a 
			FULL OUTER JOIN (Select adserver_id, 
							adserver_adslot_id,
							'IMPRESSION' metric,
							sum(booked) as booked,
							`date` 
						from TRF_AdServer_InvFuture 
						Where partition_date = {{ params.ENDDATE }}
						GROUP BY adserver_id, adserver_adslot_id,`date`) b 
				ON a.adserver_adslot_id = b.adserver_adslot_id
				AND a.adserver_id = b.adserver_id
				AND a.`date` = b.`date`
				AND a.metric = b.metric 
		) b
	) c
) d
GROUP BY 
    d.`date`, 
	d.adserver_id, 
	d.adserver_adslot_id, 
	d.adserver_adslot_name,
    d.metric, 
	d.state ,  
	d.city , 
	d.event, 
	d.pod_position,  
	d.video_position;