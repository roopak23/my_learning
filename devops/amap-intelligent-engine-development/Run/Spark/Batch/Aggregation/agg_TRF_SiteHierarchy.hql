SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_SiteHierarchy partition(partition_date = {{ params.ENDDATE }})
SELECT
    distinct a.krux_userid as dmp_userid,
    a.url_day,
    regexp_extract(a.url, '//(.*?)(\\?|/|$)', 1) as site,
    regexp_extract(a.url, '//(.*?)/(.*?)(\\?|/|$)', 2) as section,
    regexp_extract(a.url, '//(.*?)/(.*?)/(.*?)(\\?|/|$)', 3) as subsection_1id,
    regexp_extract(a.url, '//(.*?)/(.*?)/(.*?)/(.*?)(\\?|/|$)', 4) as subsection_2id,
    regexp_extract(a.url, '//(.*?)/(.*?)/(.*?)/(.*?)/(.*?)(\\?|/|$)', 5) as subsection_3id,
    regexp_extract(a.url, '//(.*?)/(.*?)/(.*?)/(.*?)/(.*?)/(.*?)(\\?|/|$)', 6) as subsection_4id,
    regexp_extract(a.url, '//(.*?)/(.*?)/(.*?)/(.*?)/(.*?)/(.*?)/(.*?)(\\?|/|$)', 7) as sitepage,
    b.publisher_userid,
    b.dmp_segment_id,
    c.segment_name
FROM STG_DMP_SiteUserData AS a
    LEFT JOIN TRF_dmp_AudienceSegmentMapNormalize AS b ON b.krux_userid = a.krux_userid and a.partition_date = b.partition_date 
    LEFT JOIN STG_DMP_AudienceSegment AS c ON c.dmp_segment_id = b.dmp_segment_id and b.partition_date = c.partition_date 
   WHERE a.partition_date= {{ params.ENDDATE }};
