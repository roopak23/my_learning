SELECT 
	`id`,
    `afsid`,
    `sa_adslot_id`,
	`sys_datasource` as `datasource`
FROM STG_SA_AFSAdSlot
WHERE partition_date = (SELECT MAX(partition_date) FROM STG_SA_AFSAdSlot)


