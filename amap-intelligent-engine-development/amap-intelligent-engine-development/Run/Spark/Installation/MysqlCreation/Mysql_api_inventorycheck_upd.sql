
-- data_activation.api_inventorycheck definition

CREATE TABLE IF NOT EXISTS api_inventorycheck_upd(
	`id` INT AUTO_INCREMENT,
	`date` datetime,
	`adserver_id` varchar(50) DEFAULT NULL,
	`adserver_adslot_id` varchar(50),
	`adserver_adslot_name` varchar(255) DEFAULT NULL,
	`audience_name` varchar(255) DEFAULT NULL,
	`metric` varchar(20) DEFAULT NULL,
	`state` varchar(150),
	`city` varchar(150),
	`event` varchar(150),
	`pod_position` varchar(50) ,
	`video_position` varchar(100) ,
	`future_capacity` int DEFAULT 0,
	`booked` int DEFAULT 0,
	`reserved` int DEFAULT 0,
	`missing_forecast` varchar(255) DEFAULT 'N',
	`missing_segment` varchar(255) DEFAULT 'N',
	`overwriting` varchar(255) DEFAULT NULL,
	`percentage_of_overwriting` double DEFAULT NULL,
	`overwritten_impressions` int DEFAULT NULL,
	`overwriting_reason` varchar(255) DEFAULT NULL,
	`use_overwrite` varchar(255) DEFAULT NULL,
	`Updated_By` varchar(255) DEFAULT NULL,
	overwritten_expiry_date datetime ,
	version BIGINT NOT NULL DEFAULT 0,
	PRIMARY KEY (`id`)
)ENGINE=InnoDB DEFAULT CHARSET=latin1;


SELECT if (
		exists(
			select distinct index_name
			from information_schema.statistics
			where table_schema = 'data_activation'
				and table_name = 'api_inventorycheck_upd'
				and index_name = 'api_inventorycheck_u1'
		),
		'select ''index api_inventorycheck_I1 exists'' _______;',
		'create UNIQUE INDEX api_inventorycheck_u1 on data_activation.api_inventorycheck_upd(`adserver_adslot_id`,`date`,`metric`,`state`, `city`,`event`,`pod_position`, `video_position`,`adserver_id`)'
	) into @a;
PREPARE stmt1
FROM @a;
EXECUTE stmt1;
DEALLOCATE PREPARE stmt1;

