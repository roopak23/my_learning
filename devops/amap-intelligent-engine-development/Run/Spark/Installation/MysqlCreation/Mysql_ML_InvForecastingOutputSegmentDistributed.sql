CREATE TABLE IF NOT EXISTS ML_InvForecastingOutputSegmentDistributed  (
	`date` DATE,
	`adserver_id` varchar(150),
	`adserver_adslot_id` varchar(150),
	`adserver_adslot_name` varchar(255),
	`State` varchar(150),
	`city` varchar(150),
	`event` varchar(150),
	`pod_position` varchar(150),
	`video_position` varchar(150),
	`metric` varchar(255),
	`future_capacity` DOUBLE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;