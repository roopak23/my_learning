select
	'STG_NC_Taxonomy' component_name ,
	{{ params.ENDDATE }} process_date,
	case
		when data_changed>0 and new_data_exists >0 then 'CHANGED'
		else 'UNCHANGED'
	end state,
	CURRENT_TIMESTAMP() create_datetime
from
	(
	select
		count(1) data_changed,
		(
		select
			count(1) new_data_exists
		FROM
			stg_nc_taxonomy a
		where
			partition_date in( {{ params.ENDDATE }} )) new_data_exists
	from
		(
		select
			count(1),
			a.taxonomy_segment_name ,
			a.taxonomy_segment_type ,
			a.platform ,
			a.platform_segment_unique_id ,
			a.platform_segment_name
		FROM
			stg_nc_taxonomy a
		where
			partition_date in( {{ params.ENDDATE }}, {{ params.ENDDATE }} -1 )
		group by
			taxonomy_segment_name,
			taxonomy_segment_type,
			platform,
			platform_segment_unique_id,
			platform_segment_name
		having
			count(1)<2
) a)b