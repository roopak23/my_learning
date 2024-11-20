-- data_activation.retrospective_reporting source

CREATE OR REPLACE
ALGORITHM = UNDEFINED VIEW `data_activation`.`retrospective_reporting` AS
select
    `FTB`.`adserver_adslot_id` AS `adserver_adslot_id`,
    `FTB`.`audience_name` AS `audience_name`,
    cast(`FTB`.`date` as date) AS `date`,
     `FTB`.`state` AS `state`,
    `FTB`.`Level1` AS `level1`,
	`FTB`.`Level2` AS `level2`,
	`FTB`.`Level3` AS `level3`,
	`FTB`.`Level4` AS `level4`,
	`FTB`.`Level5` AS `level5`,
    `FTB`.`city` AS `city`,
    `FTB`.`event` AS `event`,
    `FTB`.`future_capacity` AS `capacity`,
    'Forecasted' AS `reporttype`,
    `FTB`.`overwritten_impressions` AS `overwritten_impressions`,
	(curdate() - interval 1 day) AS `partition_date`,
    `use_overwrite` as `use_overwrite`
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
		`TB`.`level1`,
		`TB`.`level2`,
		`TB`.`level3`,
		`TB`.`level4`,
		`TB`.`level5`,
        sum(`TB`.`future_capacity`) AS `future_capacity`,
        sum(`TB`.`overwritten_impressions`) AS `overwritten_impressions`,
        `TB`.`use_overwrite`
    from
        (
        select
            `A`.`adserver_adslot_id` AS `adserver_adslot_id`,
            `A`.`date` AS `date`,
            `B`.`ParentPath` AS `ParentPath`,
			`B`.`Level1` AS `Level1`,
			`B`.`Level2` AS `Level2`,
			`B`.`Level3` AS `Level3`,
			`B`.`Level4` AS `Level4`,
			`B`.`Level5` AS `Level5`,
            `A`.`audience_name` AS `audience_name`,
            `A`.`state` AS `state`,
            `A`.`city` AS `city`,
            `A`.`event` AS `event`,
            `A`.`future_capacity` AS `future_capacity`,
            `A`.`overwritten_impressions` AS `overwritten_impressions`,
            `A`.`use_overwrite` AS `use_overwrite`
        from
            (`data_activation`.`api_inventorycheck` `A`
       left join `data_activation`.`STG_SA_Ad_Slot` `B` on
            ((`A`.`adserver_adslot_id` = `B`.`adserver_adslot_id`)))) `TB`
    group by
        `TB`.`adserver_adslot_id`,
        `TB`.`date`,
        `TB`.`ParentPath`,
        `TB`.`audience_name`,
        `TB`.`state`,
        `TB`.`city`,
        `TB`.`event`,
		`TB`. `Level1`,
		`TB`. `Level2`,
		`TB`. `Level3`,
		`TB`. `Level4`,
		`TB`. `Level5`,
        `TB`. `use_overwrite`
		) `FTB` where FTB.`date`  >=  current_date();
