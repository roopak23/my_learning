CREATE TABLE IF NOT EXISTS `STG_Adserver_InvFuture` (
	`date` DATE NOT NULL,
	`adserver_id` varchar(255) NOT NULL,
	`adserver_adslot_id` varchar(255) NOT NULL,
	`adserver_adslot_name` varchar(255) NOT NULL,
	`forcasted` INT DEFAULT 0,
	`booked` INT DEFAULT 0,
	`available` INT DEFAULT 0,
	`metric` varchar(255),
 primary key(`date`,adserver_id, adserver_adslot_id, adserver_adslot_name)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;
