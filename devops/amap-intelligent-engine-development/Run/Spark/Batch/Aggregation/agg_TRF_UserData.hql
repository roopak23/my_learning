SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_UserData partition(partition_date = {{ params.ENDDATE }})
SELECT
    url_timestamp,
    krux_userid AS dmp_userid,
    ipaddress,
    browser,
    device,
    operatingsystem,
    url,
    sitedata,
    regexp_extract(geodatadisplay, 'domain=(.*?)(&|$)', 1) as domain,
    regexp_extract(geodatadisplay, 'country=(.*?)(&|$)', 1) as country,
    regexp_extract(geodatadisplay, 'region=(.*?)(&|$)', 1) as region,
    regexp_extract(geodatadisplay, 'zipcodes=(.*?)(&|$)', 1) as zipcode
FROM STG_DMP_SiteUserData
    WHERE partition_date = {{ params.ENDDATE }};
