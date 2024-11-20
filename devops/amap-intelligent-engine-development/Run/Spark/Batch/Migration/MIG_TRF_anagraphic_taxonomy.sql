SELECT 
    `tech_id`,
    INITCAP(`taxonomy_segment_name`) as `taxonomy_segment_name`,
    `taxonomy_segment_type`,
    `newsconnect_segment_size`
FROM TRF_anagraphic_taxonomy
WHERE partition_date = (SELECT MAX(partition_date) FROM TRF_anagraphic_taxonomy)