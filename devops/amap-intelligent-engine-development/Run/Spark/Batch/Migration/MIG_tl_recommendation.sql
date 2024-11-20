SELECT 
	`tech_line_id`,
	`status`,
	`remote_id`,
	`recommendation_id`,
	`recommendation_type`,
	`recommendation_value`,
	`customer_id`,
	`original_value`,
	`recommendation_impact`
FROM TL_Recommendation
WHERE partition_date = (SELECT MAX(partition_date) FROM TL_Recommendation)