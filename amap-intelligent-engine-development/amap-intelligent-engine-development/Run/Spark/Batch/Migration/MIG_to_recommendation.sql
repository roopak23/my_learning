SELECT 
	`tech_order_id`,
	`status`,
	`remote_id`,
	`recommendation_id`,
	`recommendation_type`,
	`recommendation_value`,
	`customer_id`
FROM TO_Recommendation
WHERE partition_date = (SELECT MAX(partition_date) FROM TO_Recommendation)