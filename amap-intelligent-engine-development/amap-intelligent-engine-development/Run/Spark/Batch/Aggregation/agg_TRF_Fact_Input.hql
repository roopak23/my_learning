SET hive.auto.convert.join= FALSE;

DROP TABLE IF EXISTS trf_fact_input_temp;

create table trf_fact_input_temp as 
with zz as (select max(to_date(creation_date)) as creation_date from trf_past_campaign_performances)
select distinct tech_line_id 
,tech_order_id 
,`date`
,running_days_elapsed 
,remaining_days 
,system_id
,metric  
,daily_quantity_expected 
,cumulative_quantity_expected  
,cumulative_quantity_delivered 
,relative_quantity_delivered
,delta_quantity 
,(delta_quantity / target_quantity) as delta_perc
,status
,budget_cumulative_delivered
,budget_cumulative_expected
,budget_daily_delivered
,remaining_budget
,daily_expected_pacing
,actual_pacing
,flag_optimisation_temp
,case when (flag_optimisation_temp = 1 and `date` = creation_date) and end_date > date_add(creation_date, 3) then 1 
when (flag_optimisation_temp = 1 and `date` = date_sub(creation_date,1 )) and end_date > date_add(creation_date, 3) then 1
when (flag_optimisation_temp = 1 and `date` = date_sub(creation_date,2 )) and end_date > date_add(creation_date, 3) 
then 1 else 0 end as flag_optimisation_temp2 
,remote_id
,unit_type
,predicted_units
,quantity_delivered
,matched_units 
,forecasted_quantity 
,forecasted_pacing
from 
(select tech_line_id 
,tech_order_id
,budget
,start_date
,end_date 
,`date`
,creation_date 
,running_days_elapsed 
,remaining_days 
,system_id
,metric  
,daily_quantity_expected 
,cumulative_quantity_expected  
,cumulative_quantity_delivered 
,CASE WHEN target_quantity = 0 then 0 
ELSE (cumulative_quantity_delivered / target_quantity) END as relative_quantity_delivered
,(target_quantity - cumulative_quantity_delivered) as delta_quantity  
,status
,budget_cumulative_delivered
,((budget_daily_delivered * remaining_days) + budget_cumulative_delivered) as budget_cumulative_expected
,budget_daily_delivered
,(budget - budget_cumulative_delivered) as remaining_budget
,(budget /duration) as daily_expected_pacing
,actual_pacing
,CASE
WHEN (forecasted_pacing * 100) <= 89 and UPPER(TRIM(adserver_type)) = 'GAM' THEN 1
ELSE 0
END as flag_optimisation_temp
,target_quantity
,remote_id
,unit_type
,predicted_units
,quantity_delivered
,matched_units
,forecasted_quantity
,forecasted_pacing
from 
(select tech_line_id , tech_order_id ,budget,duration, target_quantity,start_date,end_date ,`date`,creation_date ,running_days_elapsed ,remaining_days ,system_id, metric ,daily_quantity_expected ,
(daily_quantity_expected * running_days_elapsed) as cumulative_quantity_expected, 
CASE
	WHEN UPPER(TRIM(metric)) = 'IMPRESSION' THEN SUM(impressions) OVER (PARTITION BY tech_line_id, report_id ORDER BY `date`)
	WHEN UPPER(TRIM(metric)) = 'CLICK' THEN SUM(clicks) OVER (PARTITION BY tech_line_id, report_id ORDER BY `date`)
	WHEN UPPER(TRIM(metric)) = 'CTR' THEN SUM(ctr) OVER (PARTITION BY tech_line_id, report_id ORDER BY `date`)
	WHEN UPPER(TRIM(metric)) = 'CPC' THEN SUM(cpc) OVER (PARTITION BY tech_line_id, report_id ORDER BY `date`)
	WHEN UPPER(TRIM(metric)) = 'CPM' THEN SUM(cpm) OVER (PARTITION BY tech_line_id, report_id ORDER BY `date`)
	WHEN UPPER(TRIM(metric)) = 'CPCV' THEN SUM(cpcv) OVER (PARTITION BY tech_line_id, report_id ORDER BY `date`)
	ELSE SUM(reach) OVER (PARTITION BY tech_line_id, report_id ORDER BY `date`)
	END as cumulative_quantity_delivered
,status,budget_cumulative_delivered,
(budget_cumulative_delivered / running_days_elapsed) as budget_daily_delivered,
CASE WHEN UPPER(TRIM(adserver_type)) in ('GADS','META','TTD','DV360','INVIDI','MARKETINGCLOUD' )
THEN pacing ELSE 
	CASE
    	WHEN `date` > end_date
    	THEN (budget_cumulative_delivered/(actual_pacing_denom * DATEDIFF(end_date,start_date))) * 100
    	ELSE (budget_cumulative_delivered/(actual_pacing_denom * DATEDIFF(`date`,start_date))) * 100
    	END 
END AS actual_pacing,
remote_id,
unit_type,
predicted_units,
quantity_delivered,
matched_units,
forecasted_quantity,
(budget_cumulative_delivered/forecasted_pacing_denom) as forecasted_pacing,
adserver_type from 
(SELECT DISTINCT a.tech_line_id
	,a.tech_order_id
	,a.target_quantity 
	,a.budget
	,a.duration
	,cast(from_unixtime(b.`date` div 1000, 'yyyy-MM-dd') as date) as `date`
	,d.creation_date 
	,a.start_date
	,a.end_date
	,(DATEDIFF(cast(from_unixtime(b.`date` div 1000, 'yyyy-MM-dd') as date), a.start_date)+1) as running_days_elapsed
	,CASE
        WHEN DATEDIFF(a.end_date,cast(from_unixtime(b.`date` div 1000, 'yyyy-MM-dd') as date)) > 0
        THEN DATEDIFF(a.end_date,cast(from_unixtime(b.`date` div 1000, 'yyyy-MM-dd') as date))
        ELSE 0
     END AS remaining_days
	,(a.budget/(DATEDIFF(a.end_date,a.start_date))) as actual_pacing_denom
	,a.system_id
	,a.metric
	,CASE
	WHEN UPPER(TRIM(f.adserver_type)) = 'GAM' THEN (a.target_quantity/a.duration)
	ELSE (a.budget/a.duration)
	END as daily_quantity_expected
	,c.status
	,d.budget_cumulative_delivered
	,b.report_id
	,b.impressions 
	,b.clicks 
	,b.ctr
	,b.cpc 
	,b.cpm 
	,b.cpcv ,b.reach,f.adserver_type,g.pacing
	,h.remote_id
	,h.unit_type
	,h.predicted_units
	,h.quantity_delivered
	,h.matched_units 
	,CASE
	WHEN UPPER(TRIM(f.adserver_type)) = 'GAM' THEN h.predicted_units
	WHEN UPPER(TRIM(f.adserver_type)) = 'GADS' THEN i.forecasted_quantity 
	ELSE 0
	END as forecasted_quantity
	,CASE
	WHEN UPPER(TRIM(f.adserver_type)) = 'GAM' THEN ((h.predicted_units * a.unit_net_price)/(DATEDIFF(a.end_date,a.start_date))) 
	WHEN UPPER(TRIM(f.adserver_type)) = 'GADS' THEN ((i.forecasted_quantity * a.unit_net_price)/(DATEDIFF(a.end_date,a.start_date))) 
	ELSE 0 
	END as forecasted_pacing_denom 
	from trf_campaign a 
	INNER JOIN trf_past_campaign_performances b ON (
		a.tech_line_id = b.tech_line_id
		)
	INNER JOIN stg_sa_market_order_line_details c ON (
		c.market_order_line_details_id = a.market_order_line_details_id
		AND c.partition_date = a.partition_date
		)
    INNER JOIN (select DISTINCT a1.creation_date as creation_date, a1.tech_line_id,report_id,  date_m, sum(a1.budget_required) over (PARTITION by tech_line_id order by date_m) as budget_cumulative_delivered from
        (select zz.creation_date, spc.tech_line_id,spc.report_id,  spc.system_id , cast(from_unixtime(spc.`date` div 1000, 'yyyy-MM-dd') as date) as date_m,
		CASE WHEN UPPER(TRIM(aos.adserver_type)) = 'GADS' then spend_gads else spend end as budget_required 
		from trf_past_campaign_performances spc 
		INNER JOIN stg_sa_ad_ops_system aos ON spc.system_id = aos.adserver_id 
		JOIN zz
        where  cast(from_unixtime(spc.`date` div 1000, 'yyyy-MM-dd') as date) <= zz.creation_date and spc.tech_line_id is not null
		and UPPER(TRIM(spc.report_id)) in ('REPORT0')) a1) d ON (
		b.tech_line_id  = d.tech_line_id and d.date_m = cast(from_unixtime(b.`date` div 1000, 'yyyy-MM-dd') as date)
		)
	INNER JOIN stg_sa_ad_ops_system F ON (
		a.system_id = f.adserver_id 
		AND f.partition_date = a.partition_date
		)
	LEFT JOIN (select * from trf_pacing where partition_date= {{ params.ENDDATE }}) g on (b.tech_line_id = g.tech_line_id 
	and cast(from_unixtime(b.`date` div 1000, 'yyyy-MM-dd') as date) = g.`date`)
	LEFT JOIN stg_gam_future_campaign_performances H ON (
		a.remote_id = h.remote_id 
		AND a.partition_date = h.partition_date
		) 
	LEFT JOIN trf_gads_tech_line_forecasting I ON (
		a.remote_id = i.remote_id 
		AND a.partition_date = h.partition_date
		)
	where a.partition_date = {{ params.ENDDATE }} and 
	UPPER(TRIM(b.report_id)) in ('REPORT0')) t1) t2) t3 ;

INSERT OVERWRITE TABLE trf_fact_input partition(partition_date = {{ params.ENDDATE }})
select distinct ta1.tech_line_id, ta1.tech_order_id, ta1.`date`, ta1.running_days_elapsed, ta1.remaining_days, ta1.system_id, ta1.metric, ta1.daily_quantity_expected, ta1.cumulative_quantity_expected, ta1.cumulative_quantity_delivered, ta1.relative_quantity_delivered, ta1.delta_quantity, ta1.delta_perc, ta1.status, ta1.budget_cumulative_delivered, ta1.budget_cumulative_expected,ta1.budget_daily_delivered, ta1.remaining_budget, ta1.daily_expected_pacing, ta1.actual_pacing, ta1.flag_optimisation_temp, ta3.flag_optimisation, ta1.remote_id,  ta1.unit_type, ta1.predicted_units, ta1.quantity_delivered, ta1.matched_units, ta1.forecasted_quantity, ta1.forecasted_pacing 
from trf_fact_input_temp ta1
INNER JOIN
(select tech_line_id, case when (ft_count = 3 and flag_optimisation_temp2 = 1) then 1 else 0 end as flag_optimisation from 
(select tech_line_id, count(flag_optimisation_temp2) as ft_count, flag_optimisation_temp2 from trf_fact_input_temp group by tech_line_id, flag_optimisation_temp2) ta2 ) ta3 ON (ta1.tech_line_id = ta3.tech_line_id);

DROP TABLE IF EXISTS trf_fact_input_temp;