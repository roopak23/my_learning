INSERT OVERWRITE TABLE api_segment_reach PARTITION (partition_date = {{ params.ENDDATE }})
--Records coming from GAM
SELECT  a.adserver_id,
		t.taxonomy_segment_name AS commercial_audience_name,
		a.dfp_id AS adserver_target_remote_id,
		a.dfp_name AS adserver_target_name,
		a.total_ubs AS reach,
		NULL AS impression,
		NULL AS spend
FROM STG_NC_anagraphic a
INNER JOIN STG_NC_taxonomy  t
    ON a.dfp_id = t.platform_segment_unique_id
-- AND a.dfp_name = t.platform_segment_name
   AND a.partition_date = t.partition_date
WHERE a.partition_date = {{ params.ENDDATE }}
  AND t.partition_date = {{ params.ENDDATE }}
  
UNION

--Records coming from FB and TTD
SELECT
    a.ad_ops_system AS adserver_id,
    a.commercial_audience AS commercial_audience_name,
	'all' AS adserver_target_remote_id,
	'all' AS adserver_target_name, 	
	a.reach,
	a.impression,
	a.spend
FROM STG_SA_AudienceReach a
WHERE a.partition_date = {{ params.ENDDATE }}

UNION

--Records coming from GADS
SELECT  a.adserver_id,
		t.taxonomy_segment_name AS commercial_audience_name,
		a.gads_id AS adserver_target_remote_id,
		a.gads_name AS adserver_target_name,
		a.gads_total_ubs AS reach,
		NULL AS impression,
		NULL AS spend
FROM STG_NC_GADS_Metric a
INNER JOIN STG_NC_taxonomy  t
    ON a.gads_id = t.platform_segment_unique_id
   AND a.partition_date = t.partition_date
WHERE a.partition_date = {{ params.ENDDATE }}
  AND t.partition_date = {{ params.ENDDATE }};
