CREATE TABLE IF NOT EXISTS `ML_InvForecastingOutputSegment` (
`date` Date,
`adserver_adslot_id` varchar(255),
`adserver_id` varchar(255),
`adserver_target_remote_id` varchar(255),
`adserver_target_name` varchar(255),
`adserver_target_type` varchar(255),
`adserver_target_category` varchar(255),
`adserver_target_code` varchar(255),
`metric` varchar(255),
`future_capacity` INT,
primary key(date,adserver_adslot_id,adserver_id,adserver_target_remote_id,metric))
ENGINE=InnoDB DEFAULT CHARSET=utf8  COLLATE=utf8_general_ci;

CREATE TABLE IF NOT EXISTS `ML_InvForecastingOutputSegmentInterim` (
`date` Date,
`adserver_adslot_id` varchar(255),
`adserver_id` varchar(255),
`adserver_target_remote_id` varchar(255),
`adserver_target_name` varchar(255),
`adserver_target_type` varchar(255),
`adserver_target_category` varchar(255),
`adserver_target_code` varchar(255),
`metric` varchar(255),
`future_capacity` INT,
primary key(date,adserver_adslot_id,adserver_id,adserver_target_remote_id,metric))
ENGINE=InnoDB DEFAULT CHARSET=utf8  COLLATE=utf8_general_ci;
