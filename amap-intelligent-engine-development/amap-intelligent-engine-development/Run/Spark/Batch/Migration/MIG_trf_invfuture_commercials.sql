SELECT 
	`date`,
	`adserver_adslot_id`,
	`adserver_adslot_name`,
	`catalog_item_id`,
	`available`,
	`adserver_id`,
	`metric`
FROM TRF_InvFuture_Commercials
WHERE partition_date = (SELECT MAX(partition_date) FROM TRF_InvFuture_Commercials)