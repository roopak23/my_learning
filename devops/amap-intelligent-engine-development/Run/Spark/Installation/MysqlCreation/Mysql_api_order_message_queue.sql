
-- data_activation.api_order_message_queue definition

CREATE TABLE IF NOT EXISTS `api_order_message_queue` (
	`id` bigint NOT NULL AUTO_INCREMENT,
	`market_order_id` varchar(100) NOT NULL,
	`market_order_details_id` varchar(100) NOT NULL,
	`market_order_details_status` varchar(100) DEFAULT NULL,
	`message` TEXT DEFAULT NULL,
	`action` varchar(100) DEFAULT NULL,
	`attempt_count` int NOT NULL DEFAULT '0',
	`max_attempts` int NOT NULL DEFAULT '5',
	`status` varchar(15) NOT NULL,
	`error_message` varchar(4000) DEFAULT NULL,
	`create_datetime` timestamp NOT NULL,
	`update_datetime` timestamp NOT NULL,
	PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

select if (
		exists(
			select distinct index_name
			from information_schema.statistics
			where table_schema = 'data_activation'
				and table_name = 'api_order_message_queue'
				and index_name like 'api_order_message_queue_idx1'
		),
		'select ''index api_order_message_queue_idx1 exists'' _______;',
		'create index api_order_message_queue_idx1 on api_order_message_queue(market_order_id,market_order_details_id)'
	) into @a;
PREPARE stmt1
FROM @a;
EXECUTE stmt1;
DEALLOCATE PREPARE stmt1;



