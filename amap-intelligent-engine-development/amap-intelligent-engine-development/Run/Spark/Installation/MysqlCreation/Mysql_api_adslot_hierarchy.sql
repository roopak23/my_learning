-- data_activation.adslot_hierarchy definition
CREATE TABLE IF NOT EXISTS api_adslot_hierarchy (
    adserver_id varchar(255) DEFAULT NULL,
    adserver_adslot_id varchar(255) DEFAULT NULL,
    adserver_adslot_parent_id varchar(255) DEFAULT NULL,
    UNIQUE KEY api_adslot_hierarchy_UN (adserver_adslot_id, adserver_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;
select if (
        exists(
            select distinct index_name
            from information_schema.statistics
            where table_schema = 'data_activation'
                and table_name = 'api_adslot_hierarchy'
                and index_name like 'api_adslot_hierarchy_adserver_id_IDX'
        ),
        'select ''index api_adslot_hierarchy_adserver_id_IDX exists'' _______;',
        'create index api_adslot_hierarchy_adserver_id_IDX on api_adslot_hierarchy(adserver_adslot_parent_id,adserver_id)'
    ) into @a;
PREPARE stmt1
FROM @a;
EXECUTE stmt1;
DEALLOCATE PREPARE stmt1;