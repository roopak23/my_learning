SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_AdUnitSegmentUsage PARTITION (partition_date = {{ params.ENDDATE }})
SELECT  a.adserver_adslotid AS adserver_adunit_id,
	c.adserver_id,
	c.adserver_target_remote_id,
	c.adserver_target_name,
	c.adserver_target_type,
	c.adserver_target_category,
	c.adserver_target_code
FROM STG_SA_Ad_Slot a
INNER JOIN TRF_DTFImpressions b ON
	a.adserver_id = b.adserver_id
	and a.adserver_adslotid = b.adserver_adslot_id
INNER JOIN STG_SA_Targeting c ON
	b.adserver_id = c.adserver_id
	and b.audience_segment_ids = c.adserver_target_remote_id
WHERE
  a.partition_date = {{ params.ENDDATE }}
  AND b.partition_date = {{ params.ENDDATE }}
  AND c.partition_date = {{ params.ENDDATE }};