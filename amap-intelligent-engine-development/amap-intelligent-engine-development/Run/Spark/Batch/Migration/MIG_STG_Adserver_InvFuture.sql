SELECT DISTINCT
	`date`,
	`adserver_id`,
	`adserver_adslot_id`,
	`adserver_adslot_name`,
	`forcasted`,
	`booked`,
	`available`,
	`metric`
FROM STG_Adserver_InvFuture
WHERE partition_date = (SELECT MAX(partition_date) FROM STG_Adserver_InvFuture)
