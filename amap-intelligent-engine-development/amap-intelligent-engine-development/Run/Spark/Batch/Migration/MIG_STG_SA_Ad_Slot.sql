WITH TB_Ad_slot AS
(
SELECT sys_datasource,sa_adslot_id, name, status, `size`, `type`, adserver_adslotid, adserver_id, publisher, remote_name, device, parentpath
,IF(parentpath IS NULL,CONCAT("Top level > ",remote_name),CONCAT(parentpath," > ",remote_name)) as dervied_parent, partition_date
FROM TRF_SA_Ad_Slot WHERE partition_date=(SELECT MAX(partition_date)  partition_date FROM TRF_SA_Ad_Slot)
)
SELECT 
    `sa_adslot_id`,
    `name`,
    `status`,
    `size`,
    `type`,
    `adserver_adslotid`,
    `adserver_id`,
    `publisher`,
    `remote_name`,
    `device`, 
	`sys_datasource`,
	`parentpath`,
	(case
        when ((length(`TB_Ad_slot`.`dervied_parent`) - length(replace(`TB_Ad_slot`.`dervied_parent`, '>', ''))) >= 1) then TRIM(substring_index(substring_index(`TB_Ad_slot`.`dervied_parent`, '>', 2), '>',-(1)))
        else NULL
    end) AS `level1`,
    (case
        when ((length(`TB_Ad_slot`.`dervied_parent`) - length(replace(`TB_Ad_slot`.`dervied_parent`, '>', ''))) >= 2) then TRIM(substring_index(substring_index(`TB_Ad_slot`.`dervied_parent`, '>', 3), '>',-(1)))
        else NULL
    end) AS `level2`,
    (case
        when ((length(`TB_Ad_slot`.`dervied_parent`) - length(replace(`TB_Ad_slot`.`dervied_parent`, '>', ''))) >= 3) then TRIM(substring_index(substring_index(`TB_Ad_slot`.`dervied_parent`, '>', 4), '>',-(1)))
        else NULL
    end) AS `level3`,
    (case
        when ((length(`TB_Ad_slot`.`dervied_parent`) - length(replace(`TB_Ad_slot`.`dervied_parent`, '>', ''))) >= 4) then TRIM(substring_index(substring_index(`TB_Ad_slot`.`dervied_parent`, '>', 5), '>',-(1)))
        else NULL
    end) AS `level4`,
    (case
        when ((length(`TB_Ad_slot`.`dervied_parent`) - length(replace(`TB_Ad_slot`.`dervied_parent`, '>', ''))) >= 5) then TRIM(substring_index(substring_index(`TB_Ad_slot`.`dervied_parent`, '>', 6), '>',-(1)))
        else NULL
    end) AS `level5`
FROM TB_Ad_slot
