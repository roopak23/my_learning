SELECT 
    `date`,
    `adserver_adslot_id`,
    `adserver_id`,
    `booked`
FROM TRF_AdServer_InvFuture
WHERE partition_date = {{ params.ENDDATE }}