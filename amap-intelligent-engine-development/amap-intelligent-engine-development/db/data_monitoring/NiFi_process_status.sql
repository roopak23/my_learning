CREATE TABLE IF NOT EXISTS `NiFi_process_status` (
    `source_system` varchar(100),
	`target_system` varchar(100),
	`load_id` BIGINT,
	`rundate` INT,
	`usecase_name` varchar(100),
    `dir_name` varchar(100),
    `file_name` varchar(100),
    `rows` INT,
    `step` varchar(20),
	`status` varchar(20),
	`start_ts` datetime,
	`end_ts` datetime,
    primary key(load_id, rundate, usecase_name, dir_name, file_name)
);