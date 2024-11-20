SELECT id,
     adserver_id,
     adserver_adslot_child_id,
     adserver_adslot_parent_id,
     adslot_child_id,
     adslot_parent_id,
     adserver_adslot_level
FROM trf_adslot_hierarchy
WHERE partition_date = (SELECT MAX(partition_date) FROM trf_adslot_hierarchy)