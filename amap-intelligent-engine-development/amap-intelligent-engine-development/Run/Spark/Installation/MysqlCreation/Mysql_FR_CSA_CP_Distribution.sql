
-- data_activation.FR_csa_cp_distribution definition

CREATE TABLE IF NOT EXISTS FR_csa_cp_distribution(
	`month` varchar(50),
	`common_sales_area` varchar(50),
	`content_partner` varchar(50),
	`platform_name` varchar(50),
	`catalog_item_name` varchar(50),
	`catalog_full_path` varchar(200),
	`booking_distribution` DOUBLE
)ENGINE=InnoDB DEFAULT CHARSET=latin1;