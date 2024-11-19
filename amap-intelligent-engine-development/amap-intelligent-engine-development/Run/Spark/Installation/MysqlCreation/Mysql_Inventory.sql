-- data_activation.inventory definition

CREATE TABLE IF NOT EXISTS `inventory` (
	`date` Date,
	`adserver_id` varchar(255),
	`adserver_adslot_id` varchar(255),
	`adserver_adslot_name` varchar(255),
	`metric` varchar(255),
	`state` varchar(255),
	`city` varchar(255),
	`event` varchar(255),
	`pod_position` varchar(255),
	`video_position` varchar(255),
	`future_capacity` DOUBLE,
	`booked` INT,
	primary key(`date`,`adserver_adslot_id`, `state`, `city`,`event`, `pod_position`, `video_position`)
 )ENGINE=InnoDB DEFAULT CHARSET=latin1;
