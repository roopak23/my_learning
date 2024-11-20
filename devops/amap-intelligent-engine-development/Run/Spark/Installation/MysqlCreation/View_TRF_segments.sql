-- data_activation.DataMart_Inventory source
CREATE OR REPLACE
ALGORITHM = UNDEFINED VIEW `data_activation`.`trf_segments` AS
SELECT
	a.segment_id AS segment_id,
	a.segment_name AS segment_name,
	a.technical_remote_id AS technical_remote_id,
	a.technical_remote_name AS technical_remote_name,
	a.adserver_id AS adserver_id,	
	ratio_population AS ratio_population
FROM data_activation.STG_DP_Adserver_Segment_Mapping a left join 
(select segment_id,ratio_population, max(partition_date) max_date
FROM data_activation.segments 
group by segment_id) b
on a.segment_id = b.segment_id;
