DELETE FROM TRF_AdServer_InvFuture where partition_date = {{ params.ENDDATE }};

WITH TMP_stg_adserver_invfuture AS
(
SELECT * FROM stg_adserver_invfuture
WHERE partition_date = {{ params.ENDDATE }}
UNION ALL
SELECT * FROM stg_adserver_invfuture_next_3_months where partition_date = {{ params.ENDDATE }} and
 `date` > (SELECT MAX(`date`) FROM stg_adserver_invfuture where  partition_date = {{ params.ENDDATE }})
),
TMP AS
(
SELECT  
DAY(`date`) as `date`,adserver_adslot_id,adserver_id,AVG(booked) as BOOKED
FROM TMP_stg_adserver_invfuture
GROUP BY adserver_adslot_id,adserver_id,DAY(`date`)
),
daily_distribution AS 
(
SELECT `date`,adserver_adslot_id,adserver_id,BOOKED,BOOKED/SUM(BOOKED)
OVER(PARTITION BY (adserver_adslot_id,adserver_id))  
as proportion  FROM TMP
),
monthly_forecast AS
(
SELECT sys_datasource, sys_load_id, sys_created_on, TO_DATE(CONCAT(`date`,'-01')) as `date`, adserver_adslot_id,adserver_id, adserver_adslot_name, forcasted, booked, available, metric, partition_date
FROM default.stg_adserver_invfuture_next_12_months where TO_DATE(CONCAT(`date`,'-01')) > (SELECT MAX(`date`) FROM TMP_stg_adserver_invfuture) and partition_date = {{ params.ENDDATE }}
),
future_dates AS 
(
SELECT DATE_ADD(MIN_DATE,pos) as `date` FROM 
(
SELECT posexplode(split(space(300),'')) 
)A JOIN
(SELECT MIN(`date`) as MIN_DATE FROM  monthly_forecast) B
ON 1 = 1
),
JOINED_DF AS 
(
SELECT B.adserver_adslot_id,B.adserver_id,A.`date`,B.proportion,
  C.booked FROM future_dates 
  A JOIN daily_distribution 
  B ON DAY(A.`date`) = B.`date`
  JOIN monthly_forecast C ON
  B.adserver_adslot_id = C.adserver_adslot_id AND MONTH(C.`date`) = MONTH(A.`date`)
),
Future_forecats AS 
(
SELECT `date`,adserver_adslot_id,adserver_id,
booked * proportion/SUM(proportion)
OVER(PARTITION BY adserver_adslot_id,MONTH(`DATE`)) as Booked FROM JOINED_DF
where JOINED_DF.proportion > 0
)
INSERT OVERWRITE TABLE TRF_AdServer_InvFuture partition (partition_date = {{ params.ENDDATE }})
SELECT inv2.`date`,
       FLOOR(SUM(inv2.booked)) booked ,
       inv2.adserver_adslot_id,
       inv2.adserver_id 
FROM (
      SELECT inv.`date`,
            inv.booked ,
            coalesce(smar.new_adserver_adslot_id,inv.adserver_adslot_id) adserver_adslot_id,
            inv.adserver_id 
       FROM (
          SELECT `date`,Booked as booked,adserver_adslot_id,adserver_id 
          FROM TMP_stg_adserver_invfuture
          UNION ALL
          SELECT `date`,Booked as booked,adserver_adslot_id,adserver_id 
          FROM Future_forecats 
          WHERE `date` > (SELECT MAX(`date`) FROM TMP_stg_adserver_invfuture) ) inv
       LEFT JOIN STG_Master_AdSlotRemap smar
            ON inv.adserver_adslot_id = smar.old_adserver_adslot_id 
      ) inv2
LEFT JOIN TRF_Master_AdSlotSkip skip
	   ON inv2.adserver_adslot_id = skip.adserver_adslot_id
WHERE skip.adserver_adslot_id IS NULL
GROUP BY inv2.`date`,
         inv2.adserver_adslot_id,
         inv2.adserver_id 
