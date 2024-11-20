WITH  TMP AS (
SELECT 
	TB.`date`,
	COALESCE(TB.adserver_id,FALLBACK.Non_matching_adserver_id) as adserver_id,
	TB.ad_unit_id,
	TB.adserver_adslot_name,
	TB.advertiser_id,
	TB.line_item_id,
	TB.country,
	COALESCE(CM.state , TB.region) as state,
	COALESCE(CM.geography , TB.City) as City,
	TB.Platform,
	COALESCE(TB.impressions*(video_duration/30),impressions*(22.5/30)) as impressions,
	TB.event,
	TB.pod_position,
	TB.video_position,
	audience_segment_ids AS Audience_Name,
	TB.ssp
FROM (Select 	
	a.ad_unit_id,
	b.adserver_id,
	b.adserver_adslot_name,
	a.advertiser_id,
	a.audience_segment_ids,
	a.line_item_id,
	a.country,
	a.region,
	a.city,
	Case
		WHEN (a.ssp = 'Other') THEN COALESCE((a.impressions*d.ssp_factor),a.impressions) ELSE a.impressions
	END AS impressions,
	COALESCE(CONCAT(LOWER(e.event_key), '~', regexp_extract(lower(a.custom_targeting), concat(lower(e.event_key), '=([^;]+)'), 1)),'') AS event,
	a.pod_position,
	a.video_position,
	b.Platform,
	a.ssp,
	a.`date`,
	a.partition_date
	From ( Select ad_unit_id,
		advertiser_id,
		audience_segment_ids,
		line_item_id,
		country,
		region,
		city,
		impressions,
		custom_targeting,
		pod_position,
		video_position,
		`date`,
		partition_date,
		Case
			WHEN (advertiser_id NOT IN ('4805740484', '4736245578', '5010918867', '5188306215', '4675329017', '5362284207')) THEN 'Direct'
			ELSE 'Other'
		END AS SSP
		From (Select ad_unit_id ,
			advertiser_id,
			audience_segment_ids,
			country,
			region,
			city,
			sum(Impressions) AS Impressions,
			custom_targeting,
			line_item_id,
			CASE 
			  WHEN pod_position <=0 THEN 'U'  -- Unknown
			  WHEN min_pod_position = max_pod_position THEN 'FL'  -- The only position so it's first and last
			  WHEN pod_position = min_pod_position THEN 'F'    -- FIRST
			  WHEN pod_position = max_pod_position THEN 'L'    -- LAST
			  ELSE 'M'  -- one of the middle positions
			END pod_position,
			video_position,
			`date`,
			partition_date
			FROM (Select 
			    ad_unit_id ,
				advertiser_id,
				audience_segment_ids,
				country,
				region,
				city,
				Impressions AS Impressions,
				custom_targeting,
				line_item_id,
				pod_position,
				min(greatest(pod_position,1)) OVER (PARTITION BY ad_unit_id,video_position_orig) min_pod_position,  -- date??
				max(greatest(pod_position,1)) OVER (PARTITION BY ad_unit_id,video_position_orig) max_pod_position,  -- date??
				video_position,
				`date`,
				partition_date
				From ( Select
					ad_unit_id ,
					advertiser_id,
					CAST(audience_segment_ids as STRING) as audience_segment_ids,
					country,
					region,
					city,
					count(1) AS Impressions,
					line_item_id,
					pod_position,
					CASE 
					WHEN
					video_position = 1 THEN 'PREROLL'
					WHEN
					video_position = 2 THEN 'MIDROLL'  -- deprecated
					WHEN
					video_position = 3 THEN 'POSTROLL'
					WHEN
					video_position = 0 THEN 'ANY'
					ELSE 'MIDROLL'
					END AS video_position,
					video_position video_position_orig,
					CAST(substr(`time`, 1, 10) AS DATE) AS `Date`,
					custom_targeting,
					partition_date From  stg_adserver_networkimpressions 
					WHERE  partition_date = {{ params.ENDDATE }} and LOWER(country) = 'australia' and line_item_id != 0
				GROUP BY ad_unit_id, advertiser_id,audience_segment_ids, country, region, city, partition_date, custom_targeting,line_item_id,`time`,video_position,pod_position
				UNION ALL
				Select
					ad_unit_id ,
					advertiser_id,
					audience_segment_ids,
					country,
					region,
					city,
					count(1) AS Impressions,
					line_item_id,
					pod_position,
					CASE 
					WHEN
					video_position = 1 THEN 'PREROLL'
					WHEN
					video_position = 2 THEN 'MIDROLL' -- deprecated
					WHEN
					video_position = 3 THEN 'POSTROLL'
					WHEN
					video_position = 0 THEN 'ANY'
					ELSE 'MIDROLL'
					END AS video_position,
					video_position video_position_orig,
					CAST(substr(`time`, 1, 10) AS DATE) AS `Date`,
					custom_targeting,
					partition_date From stg_adserver_networkbackfillimpressions
					Where   partition_date = {{ params.ENDDATE }} and LOWER(country) = 'australia'
					GROUP BY ad_unit_id, advertiser_id,audience_segment_ids, country, region, city, partition_date, custom_targeting, line_item_id,`time`,video_position,pod_position ) b) x 
					Group BY ad_unit_id, advertiser_id,audience_segment_ids, country, region, city, partition_date, custom_targeting, line_item_id,`date`,			
					CASE 
						WHEN pod_position <=0 THEN 'U'  -- Unknown
						WHEN min_pod_position=max_pod_position THEN 'FL'  -- The only position so it's first and last
						WHEN pod_position=min_pod_position THEN 'F'    -- FIRST
						WHEN pod_position=max_pod_position THEN 'L'    -- LAST
						ELSE 'M' -- One of the middle
						END, video_position 
					)c )a
LEFT JOIN
    stg_master_event e
    ON regexp_extract(lower(a.custom_targeting), concat(lower(e.event_key), '=([^;]+)'), 1) = lower(e.event_value)
LEFT JOIN (
	Select 
	DISTINCT
	adserver_adslot_id ,
	`date`,
	adserver_id,
	adserver_adslot_name, REGEXP_EXTRACT(adserver_adslot_name,'^(.*?)\\s*\\(', 1) AS Platform
	From stg_adserver_invhistorical where partition_date = {{ params.ENDDATE }})b
	ON a.ad_unit_id = b.adserver_adslot_id
LEFT JOIN stg_adserver_platform_factor  d
	ON lower(b.platform) = lower(d.platform_name)) TB 
LEFT JOIN (SELECT  DISTINCT(adserver_id)  Non_matching_adserver_id FROM stg_adserver_invhistorical sai 
where partition_date = {{ params.ENDDATE }} and adserver_id is not null LIMIT 1) FALLBACK ON  TRUE
LEFT JOIN (Select distinct remote_id, video_duration from STG_SA_TECH_LINE_DETAILS Where Partition_date = {{ params.ENDDATE }} and video_duration is not null ) TLD 
	ON TB.line_item_id = TLD.remote_id
LEFT JOIN stg_master_city CM
	ON LOWER(TB.city) = LOWER(cm.city)
	AND LOWER(TB.region) = LOWER(cm.state)),
TMP2 AS 
(
SELECT 
	`date`,
	adserver_id,
	ad_unit_id,
	adserver_adslot_name,
	advertiser_id,
	line_item_id,
	country,
	state,
	City,
	Platform,
	ROUND(SUM(impressions),0) as impressions,
	event,
	pod_position,
	video_position,
	Audience_Name,
	ssp
	FROM TMP
	GROUP BY 
	`date`,
	adserver_id,
	ad_unit_id,
	adserver_adslot_name,
	advertiser_id,
	line_item_id,
	country,
	state,
	City,
	Platform,
	event,
	pod_position,
	video_position,
	Audience_Name,
	ssp
)
INSERT OVERWRITE TABLE TRF_DTF_Additional_Dimensions_V2 partition (partition_date = {{ params.ENDDATE }})	
SELECT *  FROM TMP2;
