SET autocommit = 0;
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- delete adlists that has been removed from source(ansure source is not empty)
delete from api_adslot_hierarchy aah
where (
        select count(1)
        from adslot_hierarchy
    ) > 1;
-- find missing adslots or adlosts with different parent and insert/update in table
insert into api_adslot_hierarchy (
        adserver_id,
        adserver_adslot_id,
        adserver_adslot_parent_id
    ) WITH adslots_for_update as (
        select ah.adserver_id,
            ah.adserver_adslot_id,
            ah.adserver_adslot_parent_id
        from adslot_hierarchy ah
            left join api_adslot_hierarchy aah on (
                aah.adserver_id = ah.adserver_id
                and aah.adserver_adslot_id = ah.adserver_adslot_id
            )
        where aah.adserver_adslot_id is null
            or aah.adserver_adslot_parent_id <> ah.adserver_adslot_parent_id
            or COALESCE(NULLIF(aah.adserver_adslot_parent_id, ''), ' ') <> COALESCE(NULLIF(aah.adserver_adslot_parent_id, ''), ' ')
    )
select adserver_id,
    adserver_adslot_id,
    adserver_adslot_parent_id
from adslots_for_update fu ON DUPLICATE KEY
UPDATE adserver_adslot_parent_id = fu.adserver_adslot_parent_id;

COMMIT;

set autocommit = 1;