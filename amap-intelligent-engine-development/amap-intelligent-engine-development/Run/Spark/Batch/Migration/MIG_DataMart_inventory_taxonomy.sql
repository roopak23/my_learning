SELECT 
DISTINCT 
segment_name,		
catalog_item_id,
gender,
age,
interest
FROM 
(
SELECT  
	segment_name,		
	catalog_item_id,
	gender,
	age,
	interest,
	partition_date,
	RANK() OVER (ORDER BY partition_date DESC) as rn
FROM stg_sa_catalogitem 
LATERAL VIEW OUTER explode(split(commercial_audience, ';')) exploded_commercial_audience AS segment_name 
)TB  where rn = 1