WITH TMP_TRF_SA_Ad_Slot AS 
(
SELECT sa_adslot_id, name, status, `size`, `type`, adserver_adslotid, adserver_id, publisher, remote_name, device, parentpath
,IF(parentpath IS NULL,CONCAT("Top level > ",remote_name),CONCAT(parentpath," > ",remote_name)) as dervied_parent, partition_date
FROM default.TRF_SA_Ad_Slot WHERE partition_date = {{ params.ENDDATE }}
)

select
    `FTB`.`adserver_adslot_id` AS `adserver_adslot_id`,
	`FTB`.`audience_name` AS `audience_name`,
    `FTB`.`date` AS `date`,
    (case
        when ((length(`FTB`.`ParentPath`) - length(replace(`FTB`.`ParentPath`, '>', ''))) >= 1) then TRIM(substring_index(substring_index(`FTB`.`ParentPath`, '>', 2), '>',-(1)))
        else NULL
    end) AS `level1`,
    (case
        when ((length(`FTB`.`ParentPath`) - length(replace(`FTB`.`ParentPath`, '>', ''))) >= 2) then TRIM(substring_index(substring_index(`FTB`.`ParentPath`, '>', 3), '>',-(1)))
        else NULL
    end) AS `level2`,
    (case
        when ((length(`FTB`.`ParentPath`) - length(replace(`FTB`.`ParentPath`, '>', ''))) >= 3) then TRIM(substring_index(substring_index(`FTB`.`ParentPath`, '>', 4), '>',-(1)))
        else NULL
    end) AS `level3`,
    (case
        when ((length(`FTB`.`ParentPath`) - length(replace(`FTB`.`ParentPath`, '>', ''))) >= 4) then TRIM(substring_index(substring_index(`FTB`.`ParentPath`, '>', 5), '>',-(1)))
        else NULL
    end) AS `level4`,
    (case
        when ((length(`FTB`.`ParentPath`) - length(replace(`FTB`.`ParentPath`, '>', ''))) >= 5) then TRIM(substring_index(substring_index(`FTB`.`ParentPath`, '>', 6), '>',-(1)))
        else NULL
    end) AS `level5`,
    `FTB`.`state` AS `state`,
    `FTB`.`city` AS `city`,
    `FTB`.`event` AS `event`,
    `FTB`.`future_capacity` AS `capacity`,
    'Actuals' AS reporttype,
    `FTB`.`overwritten_impressions` AS `overwritten_impressions`,
	CAST(current_date - interval 1 day as Date),
    NULL as `use_overwrite`
from
    (
    select
        `TB`.`adserver_adslot_id` AS `adserver_adslot_id`,
        `TB`.`date` AS `date`,
        `TB`.`ParentPath` AS `ParentPath`,
        `TB`.`audience_name` AS `audience_name`,
        `TB`.`state` AS `state`,
        `TB`.`city` AS `city`,
        `TB`.`event` AS `event`,
        sum(`TB`.`future_capacity`) AS `future_capacity`,
        sum(`TB`.`overwritten_impressions`) AS `overwritten_impressions`
    from
        (
        select
            `A`.`adserver_adslot_id` AS `adserver_adslot_id`,
            `A`.`date` AS `date`,
            `B`.`ParentPath` AS `ParentPath`,
            '' `audience_name`,
            `A`.`state` AS `state`,
            `A`.`city` AS `city`,
            `A`.`event` AS `event`,
            `A`.`impressions` AS `future_capacity`,
            '' AS `overwritten_impressions`
        from
            ((SELECT * FROM `trf_dtf_additional_dimensions` where partition_date = {{ params.ENDDATE }})`A`
        left join (SELECT * FROM `TMP_TRF_SA_Ad_Slot` where partition_date = {{ params.ENDDATE }} and parentpath is not null ) `B` on
            `A`.`adserver_adslot_id` = `B`.`adserver_adslotid`)) `TB`
    group by
        `TB`.`adserver_adslot_id`,
        `TB`.`date`,
        `TB`.`ParentPath`,
        `TB`.`audience_name`,
        `TB`.`state`,
        `TB`.`city`,
        `TB`.`event`) `FTB`
