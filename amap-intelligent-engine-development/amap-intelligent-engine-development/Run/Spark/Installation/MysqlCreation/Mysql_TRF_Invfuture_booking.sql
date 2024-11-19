CREATE TABLE IF NOT EXISTS `TRF_Invfuture_booking` (
	`date` DATE NOT NULL,
	`adserver_adslot_id` varchar(255) NOT NULL,
	`adserver_id` varchar(255) NOT NULL,
	`booked` INT DEFAULT 0,
 primary key(`date`, adserver_adslot_id)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;
