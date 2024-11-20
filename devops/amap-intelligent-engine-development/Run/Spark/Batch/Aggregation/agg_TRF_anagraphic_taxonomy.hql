with total_ubs as(
select sum(b.total_ubs) total_ubs ,
	    trim(a.taxonomy_segment_name) taxonomy_segment_name
from STG_NC_taxonomy a,
	stg_nc_anagraphic b
where a.partition_date = {{ params.ENDDATE }}
  AND b.partition_date = {{ params.ENDDATE }}
  AND b.dfp_id = a.platform_segment_unique_id
  AND a.platform = 'GAM'
group by trim(a.taxonomy_segment_name))
INSERT OVERWRITE TABLE TRF_anagraphic_taxonomy PARTITION (partition_date = {{ params.ENDDATE }})
SELECT md5(coalesce(a.taxonomy_segment_name, ' ')|| '_' || coalesce(a.taxonomy_segment_type, ' ')|| '_' || coalesce(a.platform, ' ')|| '_' || coalesce(a.platform_segment_unique_id, ' ')|| '_' || coalesce(a.platform_segment_name, ' ')) tech_id,
       trim(a.taxonomy_segment_name) taxonomy_segment_name,
	   a.taxonomy_segment_type,
	   (select total_ubs.total_ubs from total_ubs where trim(total_ubs.taxonomy_segment_name) = trim(a.taxonomy_segment_name) ) reach
 FROM STG_NC_taxonomy a
WHERE a.partition_date = {{ params.ENDDATE }}
GROUP BY a.taxonomy_segment_name,
		a.taxonomy_segment_type,
	 	md5(coalesce(a.taxonomy_segment_name, ' ')|| '_' || coalesce(a.taxonomy_segment_type, ' ')|| '_' || coalesce(a.platform, ' ')|| '_' || coalesce(a.platform_segment_unique_id, ' ')|| '_' || coalesce(a.platform_segment_name, ' '));

	
		