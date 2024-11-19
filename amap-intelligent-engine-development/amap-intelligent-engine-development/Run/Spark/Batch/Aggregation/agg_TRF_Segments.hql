SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_Segments partition(partition_date = {{ params.ENDDATE }})
SELECT 
    a.url_day as `date`,
    a.dmp_segment_id ,
    max(a.segment_name),
    COUNT( DISTINCT a.dmp_userid),
    COUNT(a.dmp_userid),
    max(b.category),
    max(b.subcategory)
    FROM TRF_SiteHierarchy AS a
JOIN STG_DMP_AudienceSegment AS b ON a.dmp_segment_id = b.dmp_segment_id 
AND a.partition_date = b.partition_date
WHERE a.partition_date ={{ params.ENDDATE }}
GROUP BY a.dmp_segment_id,a.url_day
