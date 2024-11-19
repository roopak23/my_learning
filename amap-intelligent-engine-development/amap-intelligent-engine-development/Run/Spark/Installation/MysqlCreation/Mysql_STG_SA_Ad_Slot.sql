CREATE TABLE if not exists `STG_SA_Ad_Slot` (
  `sa_adslot_id` varchar(255),
  `name` varchar(255) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `size` varchar(255) DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  `adserver_adslot_id` varchar(255) DEFAULT NULL,
  `adserver_id` varchar(255) DEFAULT NULL,
  `publisher` varchar(255) DEFAULT NULL,
  `remote_name` varchar(255) DEFAULT NULL,
  `device` varchar(255) DEFAULT NULL, 
  `datasource` varchar(255) DEFAULT NULL,
  `ParentPath` varchar(255) DEFAULT NULL,
  `Level1` varchar(100) DEFAULT NULL,
  `Level2` varchar(100) DEFAULT NULL,
  `Level3` varchar(100) DEFAULT NULL,
  `Level4` varchar(100) DEFAULT NULL,
  `Level5` varchar(100) DEFAULT NULL,
  primary key(sa_adslot_id)
) ;
SELECT if (
		exists(
			select distinct index_name
			from information_schema.statistics
			where table_schema = 'data_activation'
				and table_name = 'STG_SA_Ad_Slot'
				and index_name = 'STG_SA_Ad_Slot_I1'
		),
		'select ''index STG_SA_Ad_Slot_I1 exists'' _______;',
		'create index STG_SA_Ad_Slot_I1 on data_activation.STG_SA_Ad_Slot(Level1,Level2,Level3,Level4,Level5)'
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
				and table_name = 'STG_SA_Ad_Slot'
				and index_name = 'STG_SA_Ad_Slot_status_IDX'
		),
		'select ''index STG_SA_Ad_Slot_status_IDX exists'' _______;',
		'create index STG_SA_Ad_Slot_status_IDX on data_activation.STG_SA_Ad_Slot(status)'
	) into @a;
PREPARE stmt2
FROM @a;
EXECUTE stmt2;
DEALLOCATE PREPARE stmt2;
