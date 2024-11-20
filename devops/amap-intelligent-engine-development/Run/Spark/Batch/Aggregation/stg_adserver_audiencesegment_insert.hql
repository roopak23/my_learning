INSERT INTO default.stg_adserver_audiencesegment (sys_datasource,
                                                  sys_load_id,
                                                  sys_created_on,
                                                  adserver_id,
                                                  adserver_target_remote_id,
                                                  adserver_target_name,
                                                  adserver_target_type,
                                                  status,
                                                  dataprovider,
                                                  segment_type,
                                                  partition_date)
SELECT DISTINCT sys_datasource,
                sys_load_id,
                sys_created_on,
                adserver_id,
                'all',
                'audience',
                'audience',
                'active',
                NULL,
                'audience',
                partition_date
FROM default.stg_adserver_audiencesegment
WHERE partition_date = {{ params.ENDDATE }};