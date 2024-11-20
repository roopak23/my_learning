CREATE TABLE IF NOT EXISTS `DataMart_CAR_Geo` (
    `userid` varchar(255),
	`device` varchar(255),
    `count_device` INT,
	`country` varchar(255),
	`count_country` INT,
	`region` varchar(255),
	`count_region` INT,
	`zipcode` INT,
	`count_zipcode` INT,
primary key(userid,device)
);

