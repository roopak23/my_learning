SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE CAR_Geo partition(partition_date = {{ params.ENDDATE }})
SELECT
    b.userid,
    MAX(a.device),
    COUNT(a.device) as sum_device,
    MAX(a.country),
    COUNT(a.country) as sum_country,
    MAX(a.region),
    COUNT(a.region) as sum_region,
    MAX(a.zipcode),
    COUNT(a.zipcode) as sum_zipcode
FROM TRF_UserData as a
    JOIN AUD_STG_UserMatching as b on b.dmp_userid = a.dmp_userid and b.partition_date = a.partition_date
WHERE a.partition_date = {{ params.ENDDATE }}
GROUP BY b.userid;