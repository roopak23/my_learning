SELECT 
	`tech_id`,
	`platform`,
	`platform_segment_unique_id`,
	INITCAP(`platform_segment_name`) as `platform_segment_name`,
	`action`,
	`segment_type`,
	`taxonomy_segment_type`,
	INITCAP(`taxonomy_segment_name`) as `taxonomy_segment_name`,
	`news_connect_id`
FROM TRF_anagraphic_segment_enhanced
WHERE partition_date = (SELECT MAX(partition_date) FROM TRF_anagraphic_segment_enhanced)