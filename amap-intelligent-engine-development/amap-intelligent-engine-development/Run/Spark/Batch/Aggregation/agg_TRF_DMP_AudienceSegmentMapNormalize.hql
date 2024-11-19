SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_DMP_AudienceSegmentMapNormalize PARTITION (partition_date = {{ params.ENDDATE }})
SELECT
    sys_datasource
    ,krux_userid
	,publisher_userid
	,dmpsegmentid
FROM (
	SELECT
	    sys_datasource
	    ,krux_userid
		,publisher_userid
		,dmpsegmentid
	FROM STG_DMP_AudienceSegmentMap LATERAL VIEW OUTER explode(split(dmp_segment_id, ',')) a AS dmpsegmentid
	WHERE partition_date = {{ params.ENDDATE }}
	) b;