
-- data_activation.batch_status definition


CREATE TABLE IF NOT EXISTS batch_status(
	`date` datetime NOT NULL,
	`status` varchar(50) NOT NULL
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

insert into batch_status
SELECT NOW(),
	'COMPLETED'
WHERE NOT EXISTS (
		SELECT 1
		from batch_status
	);