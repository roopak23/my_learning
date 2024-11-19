SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE trf_targeting_update PARTITION (partition_date = {{ params.ENDDATE }})
SELECT
    'Audience Segment' AS adserver_target_type,
    a.dfp_id AS adserver_target_remote_id,
	a.dfp_name AS adserver_target_name,
	a.adserver_id
FROM STG_NC_anagraphic a
WHERE a.dfp_id NOT IN (SELECT b.adserver_target_remote_id FROM STG_SA_Targeting b
                              WHERE b.partition_date = {{ params.ENDDATE }})
 AND a.partition_date = {{ params.ENDDATE }};
