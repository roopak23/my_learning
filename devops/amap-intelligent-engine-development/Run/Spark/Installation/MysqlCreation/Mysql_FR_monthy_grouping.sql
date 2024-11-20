
-- data_activation.FR_monthy_grouping definition

CREATE TABLE IF NOT EXISTS FR_monthy_grouping(
	`month` varchar(50),
	`catalog_item_name` varchar(50),
	`catalog_full_path` varchar(200),
	`adserver_adslot_id` varchar(50),
	`adserver_adslot_name` varchar(100),
	`monthly_booking` INTEGER
)ENGINE=InnoDB DEFAULT CHARSET=latin1;