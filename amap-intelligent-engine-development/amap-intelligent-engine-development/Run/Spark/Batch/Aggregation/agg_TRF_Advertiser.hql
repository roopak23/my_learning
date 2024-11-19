SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_Advertiser partition(partition_date = {{ params.ENDDATE }})
SELECT DISTINCT a.account_id AS advertiser_id   --> PK
	,a.account_name AS advertiser_name
	,a.record_type
	,a.industry
	,b.brand_name
	,b.brand_id                                 --> PK
	,c.ad_ops_system AS adserver_id             --> PK
FROM stg_sa_account a
JOIN stg_sa_amap_account_ad_ops_syst c 
  ON c.account_id = a.account_id
LEFT JOIN (SELECT DISTINCT account_id
				,brand_id
				,brand_name
				,partition_date 
		     FROM STG_SA_Brand
			WHERE partition_date = {{ params.ENDDATE }}
		  ) b
	   ON a.account_id = b.account_id
	  AND a.partition_date = b.partition_date
WHERE a.partition_date = {{ params.ENDDATE }} 
  AND c.partition_date = {{ params.ENDDATE }} 
  AND UPPER(a.account_type) = 'ADVERTISER';