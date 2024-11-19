SET autocommit = 0;
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
delete from api_frequency_cap_factor
where (
        select count(1)
        from master_frequency_cap_factor
    ) > 1
    AND (
        select count(1)
        from api_adslot_hierarchy
    ) > 1;

insert into api_frequency_cap_factor(
        adserver_adslot_id,
        aserver_adslot_name,
        time_unit,
        num_time_units,
        max_impressions,
        factor
    )
SELECT adserver_adslot_id,
    aserver_adslot_name,
    time_unit,
    num_time_units,
    max_impressions,
    factor
FROM master_frequency_cap_factor a ON DUPLICATE KEY
UPDATE factor = a.factor;

insert into api_frequency_cap_factor(
        adserver_adslot_id,
        aserver_adslot_name,
        time_unit,
        num_time_units,
        max_impressions,
        factor
    ) with recursive cte (
        adserver_id,
        adserver_adslot_id,
        adserver_adslot_parent_id,
        root_parent
    ) as (
        select a.adserver_id,
            a.adserver_adslot_id,
            a.adserver_adslot_parent_id,
            f.adserver_adslot_id root_parent
        from api_adslot_hierarchy a
            join (
                select distinct adserver_adslot_id
                from master_frequency_cap_factor
            ) f on a.adserver_adslot_parent_id = f.adserver_adslot_id
        union all
        select aah.adserver_id,
            aah.adserver_adslot_id,
            aah.adserver_adslot_parent_id,
            cte.root_parent root_parent
        from api_adslot_hierarchy aah
            inner join cte on aah.adserver_adslot_parent_id = cte.adserver_adslot_id
            and aah.adserver_id = cte.adserver_id
    )
select cte.adserver_adslot_id,
    mfc.aserver_adslot_name,
    mfc.time_unit,
    mfc.num_time_units,
    mfc.max_impressions,
    mfc.factor
from cte
    join master_frequency_cap_factor mfc 
on cte.root_parent = mfc.adserver_adslot_id ON DUPLICATE KEY
UPDATE factor = mfc.factor;
COMMIT;
