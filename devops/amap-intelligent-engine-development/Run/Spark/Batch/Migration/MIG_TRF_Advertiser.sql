SELECT advertiser_id ,
       advertiser_name,
       record_type ,
       industry ,
       brand_name ,
       brand_id ,
       coalesce(adserver_id,'') adserver_id
FROM TRF_Advertiser
WHERE partition_date = (SELECT MAX(partition_date) FROM TRF_Advertiser)
