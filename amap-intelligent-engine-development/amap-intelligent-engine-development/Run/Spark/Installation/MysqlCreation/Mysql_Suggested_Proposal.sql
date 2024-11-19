CREATE TABLE IF NOT EXISTS `Suggested_Proposal` (
`dm_id` varchar(255)   NOT NULL,
`simulation_id` varchar(150) NOT NULL,
`advertiser_id` varchar(150) DEFAULT NULL,
`brand_id` varchar(150) DEFAULT NULL,
`avg_daily_budget` double DEFAULT NULL,
`start_date` date DEFAULT NULL,
`end_date` date DEFAULT NULL,
`audience` varchar(255) DEFAULT NULL,
`objective` varchar(150) DEFAULT NULL,
PRIMARY KEY (`dm_id`)
);