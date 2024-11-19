SELECT 
ROW_NUMBER() OVER () AS Id,
platform_name,
dimension_level,
CASE
WHEN
dimension = 'act' THEN 'Australian Capital Territory'
WHEN
dimension = 'nsw' THEN 'New South Wales'
WHEN
dimension = 'tas' THEN 'Tasmania'
WHEN
dimension = 'wa' THEN 'New South Wales'
WHEN
dimension = 'nt' THEN 'Northern Territory'
WHEN
dimension = 'qld' THEN 'Queensland'
WHEN
dimension = 'sa' THEN 'South Australia'
WHEN
dimension = 'vic' THEN 'Victoria'
END as dimension,
audience_name,
`% audience` as percent_audience
FROM stg_adserver_audiencefactoring
where partition_date = (SELECT MAX(partition_date) FROM stg_adserver_audiencefactoring) AND dimension_level = 'State'