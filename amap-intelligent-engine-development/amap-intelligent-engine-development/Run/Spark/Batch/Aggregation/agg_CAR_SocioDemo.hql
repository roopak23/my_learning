SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE CAR_SocioDemo partition(partition_date = {{ params.ENDDATE }})
SELECT
    b.userid,
    MAX(regexp_extract(a.segment_name, 'Age_(.*?)_', 1)) as age,
    MAX(regexp_extract(a.segment_name, 'Gender_(.*?)_', 1)) as gender
FROM TRF_SiteHierarchy as a
    JOIN AUD_STG_UserMatching as b on b.dmp_userid = a.dmp_userid and b.partition_date = a.partition_date
WHERE a.partition_date = {{ params.ENDDATE }}
GROUP BY b.userid;
