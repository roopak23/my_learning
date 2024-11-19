
-- data_activation.api_order_process_state definition
CREATE TABLE IF NOT EXISTS `api_order_process_state` (
	`market_order_details_id` varchar(100) NOT NULL,
	`market_order_id` varchar(100) NOT NULL,
	`status` varchar(15) NOT NULL,
	`create_datetime` timestamp NOT NULL,
	`update_datetime` timestamp NOT NULL,
	PRIMARY KEY (`market_order_id`, `market_order_details_id`)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;


