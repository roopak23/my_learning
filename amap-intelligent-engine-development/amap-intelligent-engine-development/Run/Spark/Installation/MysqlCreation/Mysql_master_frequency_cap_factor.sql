-- data_activation.api_frequency_cap_factor definition

CREATE TABLE IF NOT EXISTS master_frequency_cap_factor (
	adserver_adslot_id varchar(255) NOT NULL,
	aserver_adslot_name varchar(255),
	time_unit varchar(255) NOT NULL,
	num_time_units INTEGER,
	max_impressions INTEGER,
	factor DOUBLE DEFAULT 0.0,
	PRIMARY KEY (adserver_adslot_id, time_unit, num_time_units,max_impressions)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;