CREATE OR REPLACE ALGORITHM = UNDEFINED VIEW `data_activation`.`segments` AS
SELECT `a`.`campaign_segment_id` AS `segment_id`,
	`b`.`name` AS `segment_name`,
	`a`.`elements` AS `segment_size`,
	'description' AS `attribute_name`,
	`b`.`description` AS `attribute_value`,
	'custom_segment' AS `segment_type`,
	`a`.`weight` AS `ratio_population`,
	`a`.`start_date` AS `partition_date`
FROM (`seg_tool`.`execution_history` `a`
LEFT JOIN `seg_tool`.`campaign_segment` `b`
on((`a`.`campaign_segment_id` = `b`.`id`)))
WHERE (`a`.`status` = 'COMPLETED');