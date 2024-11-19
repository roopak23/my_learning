SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_InvFutureSegment PARTITION (partition_date = {{ params.ENDDATE }})
SELECT 
	a.`date` AS `date`,
	a.adserver_id AS adserver_id,
	a.adserver_adslot_id,
	a.metric,
	b.city as city,
	b.state as state,
	b.event as event,
	a.forcasted  AS forcasted,
	a.booked  AS booked,
	a.available  AS available
FROM   STG_adserver_InvFuture a 
INNER JOIN trf_dtf_additional_dimensions b ON  a.adserver_adslot_id= b.adserver_adslot_id
where a.partition_date = {{ params.ENDDATE }} 
and b.partition_date = {{ params.ENDDATE }}
