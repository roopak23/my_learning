CREATE TABLE IF NOT EXISTS `STG_SA_Targeting` (
    `target_id` varchar(255),
    `adserver_target_type` varchar(255),
    `adserver_target_remote_id` varchar(255),
    `adserver_target_name` varchar(1000),
    `adserver_id` varchar(255),
    `adserver_target_category` varchar(255),
    `adserver_target_code` varchar(255),
    `datasource` varchar(255) DEFAULT NULL,
    primary key(target_id, adserver_target_remote_id, adserver_id)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8  COLLATE=utf8_general_ci;
