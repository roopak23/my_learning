SELECT 
	adserver_id, 
	adserver_name, 
	adserver_type, 
	sys_datasource
FROM stg_sa_ad_ops_system
WHERE partition_date = (SELECT MAX(partition_date) FROM stg_sa_ad_ops_system