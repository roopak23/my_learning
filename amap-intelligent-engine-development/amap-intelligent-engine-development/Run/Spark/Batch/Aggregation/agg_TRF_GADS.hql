SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE TRF_GADS PARTITION (partition_date = {{ params.ENDDATE }})
select `date`,creation_date,tech_order_id,tech_line_id,remote_id,report_id,system_id,adserver_type,start_date,end_date,total_line_spend,total_order_spend,total_price,
CASE
    WHEN `date` > end_date
    THEN (total_order_spend/((total_price/(DATEDIFF(end_date,start_date))) * DATEDIFF(end_date,start_date))) * 100
    ELSE (total_order_spend/((total_price/(DATEDIFF(end_date,start_date))) * DATEDIFF(`date`,start_date))) * 100
END AS gads_pacing from 
(select `date`,creation_date,tech_order_id,tech_line_id,remote_id,report_id,system_id,adserver_type,start_date,end_date,total_line_spend,SUM(total_line_spend) OVER(PARTITION BY tech_order_id,`date`) as total_order_spend,total_price from 
(select `date`,creation_date,tech_order_id,tech_line_id,remote_id,report_id,system_id,adserver_type,start_date,end_date, SUM(spend_gads) OVER(PARTITION BY tech_line_id,report_id ORDER BY `date`) as total_line_spend,total_price 
from 
(select a.date_converted as `date`,a.creation_date,c.tech_order_id,b.tech_line_id,a.remote_id,a.report_id,d.adserver_id,d.adserver_type,cast(from_unixtime(b.start_date  div 1000, 'yyyy-MM-dd') as date) as start_date ,cast(from_unixtime(b.end_date  div 1000, 'yyyy-MM-dd') as date) as end_date,a.spend_gads,c.total_price,c.system_id  
FROM trf_past_campaign_performances A
INNER JOIN stg_sa_tech_line_details B ON a.tech_line_id = b.tech_line_id  
INNER JOIN stg_sa_tech_order C ON b.tech_order_id = c.tech_order_id  
INNER JOIN stg_sa_ad_ops_system D ON c.system_id  = d.adserver_id  
where UPPER(TRIM(d.adserver_type)) = 'GADS' and UPPER(TRIM(a.report_id)) = 'REPORT0' and b.partition_date = {{ params.ENDDATE }} and c.partition_date = {{ params.ENDDATE }} and d.partition_date = {{ params.ENDDATE }} ) tg) tg1) tg2
