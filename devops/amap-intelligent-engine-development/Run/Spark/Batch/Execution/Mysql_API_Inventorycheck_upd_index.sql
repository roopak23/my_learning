-- Recrate indexes on api_inventory_chec_upd
SELECT if (
		exists(
			select distinct index_name
			from information_schema.statistics
			where table_schema = 'data_activation'
				and table_name = 'api_inventorycheck_upd'
				and index_name = 'api_inventorycheck_I1'
		),
		'select ''index api_inventorycheck_I1 exists'' _______;',
		'create index api_inventorycheck_I1 on data_activation.api_inventorycheck_upd(date,adserver_adslot_id)'
	) into @a;
PREPARE stmt1
FROM @a;
EXECUTE stmt1;
DEALLOCATE PREPARE stmt1;


SELECT if (
		exists(
			select distinct index_name
			from information_schema.statistics
			where table_schema = 'data_activation'
				and table_name = 'api_inventorycheck_upd'
				and index_name = 'api_inventorycheck_I2'
		),
		'select ''index api_inventorycheck_I2 exists'' _______;',
		'create index api_inventorycheck_I2 on data_activation.api_inventorycheck_upd(date,event)'
	) into @b;
PREPARE stmt2
FROM @b;
EXECUTE stmt2;
DEALLOCATE PREPARE stmt2;

