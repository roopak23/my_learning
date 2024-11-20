SELECT
    adserver_adunit_id ,
    adserver_adslot_name,
    adserver_id ,
    sitepage ,
    adserver_target_remote_id ,
    adserver_target_name ,
    adserver_target_type ,
    adserver_target_category ,
    adserver_target_code
FROM TRF_AdunitSegmentUsage
WHERE partition_date = (SELECT MAX(partition_date) FROM TRF_AdunitSegmentUsage)
 