SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_anagraphic_segment_enhanced PARTITION (partition_date = {{ params.ENDDATE }})
SELECT md5(coalesce(a.taxonomy_segment_name,' ')||'_'||coalesce(a.taxonomy_segment_type,' ')||'_'||coalesce(a.platform,' ')||'_'||coalesce(a.platform_segment_unique_id,' ')||'_'||coalesce(a.platform_segment_name,' ')) tech_id,
		a.platform,
		a.platform_segment_unique_id,
		a.platform_segment_name,
		'U' AS action,
		'full' AS segment_type,
		'AudienceSegment' AS taxonomy_segment_type,
		TRIM(a.taxonomy_segment_name) taxonomy_segment_name,
		a.news_connect_id
	FROM STG_NC_taxonomy a
WHERE a.partition_date = {{ params.ENDDATE }};