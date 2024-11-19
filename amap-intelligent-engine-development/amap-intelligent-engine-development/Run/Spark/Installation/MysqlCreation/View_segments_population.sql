CREATE OR REPLACE ALGORITHM = UNDEFINED VIEW `data_activation`.`segments_population` AS
	SELECT `a`.`campaign_segment_id` AS `segment_id`,
	`b`.`name` AS `segment_name`,
	`a`.`elements` AS `segment_size`,
	`c`.`line_id` AS `dp_userid`,
	`c`.`deleted_flag` AS `flag_deleted_user`,
	`c`.`partition_date` AS `partition_date`
FROM ((`seg_tool`.`execution_history` `a`
LEFT JOIN `seg_tool`.`campaign_segment` `b`
on((`a`.`campaign_segment_id` = `b`.`id`)))
JOIN `seg_tool`.`execution_population` `c`
on((`a`.`id` = `c`.`execution_id`)))
WHERE ((`a`.`status` = 'COMPLETED') and (`c`.`status` = 'WORKED'))
AND `c`.`partition_date` = (SELECT max(`partition_date`) FROM `seg_tool`.`execution_population`);