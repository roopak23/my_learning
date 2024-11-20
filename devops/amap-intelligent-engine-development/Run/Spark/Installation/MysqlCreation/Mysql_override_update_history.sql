CREATE TABLE IF NOT EXISTS override_update_history
(
	`id` int ,
	`date` datetime,
	`adserver_id` varchar(50) DEFAULT NULL,
	`adserver_adslot_id` varchar(50),
	`adserver_adslot_name` varchar(255) DEFAULT NULL,
	`audience_name` varchar(255) DEFAULT NULL,
	`metric` varchar(20) DEFAULT NULL,
	`state` varchar(150),
	`city` varchar(150),
	`event` varchar(150),
	`pod_position` varchar(50) ,
	`video_position` varchar(100) ,
	`future_capacity` int DEFAULT 0,
	`booked` int DEFAULT 0,
	`reserved` int DEFAULT 0,
	`missing_forecast` varchar(255) DEFAULT 'N',
	`missing_segment` varchar(255) DEFAULT 'N',
	`overwriting` varchar(255) DEFAULT NULL,
	`percentage_of_overwriting` varchar(255) DEFAULT NULL,
	`overwritten_impressions` int DEFAULT NULL,
	`overwriting_reason` varchar(255) DEFAULT NULL,
	`use_overwrite` varchar(255) DEFAULT NULL,
    `update_date_time` Datetime,
    `updated_by` varchar(60),
    `active_record_status` varchar(60),
	`overwritten_expiry_date` datetime
);

SELECT if (
		exists(
			select distinct index_name
			from information_schema.statistics
			where table_schema = 'data_activation'
				and table_name = 'override_update_history'
				and index_name = 'override_update_history_I1'
		),
		'select ''index override_update_history_I1 exists'' _______;',
		'create index override_update_history_I1 on data_activation.override_update_history(date,adserver_adslot_id)'
	) into @a;
PREPARE stmtovr
FROM @a;
EXECUTE stmtovr;
DEALLOCATE PREPARE stmtovr;




SELECT if (
		exists(
			select distinct index_name
			from information_schema.statistics
			where table_schema = 'data_activation'
				and table_name = 'override_update_history'
				and index_name = 'override_update_history_I2'
		),
		'select ''index override_update_history_I2 exists'' _______;',
		'create index override_update_history_I2 on data_activation.override_update_history(update_date_time)'
	) into @a;
PREPARE stmtovr
FROM @a;
EXECUTE stmtovr;
DEALLOCATE PREPARE stmtovr;
