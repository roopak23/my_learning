SELECT
    userid,
    device,
	count_device,
    country,
	count_country,
    region,
	count_region,
    zipcode,
	count_zipcode
FROM CAR_Geo
WHERE partition_date = {{ params.ENDDATE }}