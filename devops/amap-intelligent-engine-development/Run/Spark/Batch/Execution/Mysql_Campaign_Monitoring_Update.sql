UPDATE campaign_monitoring SET city = CASE
WHEN UPPER(TRIM(city)) = 'SYDNEY' THEN 'Sydney' 
WHEN UPPER(TRIM(city)) = 'MELBOURNE' THEN 'Melbourne' 
WHEN UPPER(TRIM(city)) = 'BR=BANE' THEN 'Brisbane' 
WHEN UPPER(TRIM(city)) = 'PERTH' THEN 'Perth' 
WHEN UPPER(TRIM(city)) = 'ADELAIDE' THEN 'Adelaide' 
WHEN UPPER(TRIM(city)) = 'GOLDCOAST' THEN 'Gold Coast' 
WHEN UPPER(TRIM(city)) = 'NEWCASTLE' THEN 'Newcastle' 
WHEN UPPER(TRIM(city)) = 'CANBERRA' THEN 'Canberra' 
WHEN UPPER(TRIM(city)) = 'SUNSHINECOAST' THEN 'Sunshine Coast' 
WHEN UPPER(TRIM(city)) = 'CENTRALCOAST' THEN 'Central Coast' 
WHEN UPPER(TRIM(city)) = 'WOLLONGONG' THEN 'Wollongong' 
WHEN UPPER(TRIM(city)) = 'GEELONG' THEN 'Geelong' 
WHEN UPPER(TRIM(city)) = 'HOBART' THEN 'Hobart' 
WHEN UPPER(TRIM(city)) = 'TOWNSVILLE' THEN 'Townsville' 
WHEN UPPER(TRIM(city)) = 'CAIRNS' THEN 'Cairns' 
WHEN UPPER(TRIM(city)) = 'TOOWOOMBA' THEN 'Toowoomba' 
WHEN UPPER(TRIM(city)) = 'DARWIN' THEN 'Darwin' 
WHEN UPPER(TRIM(city)) = 'BALLARAT' THEN 'Ballarat' 
WHEN UPPER(TRIM(city)) = 'BENDIGO' THEN 'Bendigo' 
WHEN UPPER(TRIM(city)) = 'ALBURY' OR  CITY = 'Wodonga' THEN 'Albury–Wodonga' 
WHEN UPPER(TRIM(city)) = 'AUCKLAND' THEN 'Auckland' 
WHEN UPPER(TRIM(city)) = 'CHRISTCHURCH' THEN ' Christchurch' 
WHEN UPPER(TRIM(city)) = 'WELLINGTON' THEN 'Wellington' 
WHEN UPPER(TRIM(city)) = 'HAMILTON' THEN 'Hamilton' 
WHEN UPPER(TRIM(city)) = 'TAURANGA' THEN 'Tauranga' 
ELSE 'Others' END;

update campaign_monitoring set country = CASE 
WHEN UPPER(TRIM(country)) = "AUSTRALIA" THEN "Australia" 
WHEN UPPER(TRIM(country)) = "NEWZEALAND" THEN "New Zealand"
ELSE "Others"
END;