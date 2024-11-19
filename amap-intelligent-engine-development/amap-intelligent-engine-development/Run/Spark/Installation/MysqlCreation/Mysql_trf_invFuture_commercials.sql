CREATE TABLE IF NOT EXISTS `trf_invfuture_commercials` (
	`date` DATE NOT NULL,
	`adserver_adslot_id` varchar(200) NOT NULL,
	`adserver_adslot_name` varchar(255),
	`catalog_item_id` varchar(255) NOT NULL,
	`available` INT,
	`adserver_id` varchar(155) NOT NULL,
	`metric` varchar(155),
	primary key(`date`, adserver_adslot_id, catalog_item_id, adserver_id, metric)
	);
