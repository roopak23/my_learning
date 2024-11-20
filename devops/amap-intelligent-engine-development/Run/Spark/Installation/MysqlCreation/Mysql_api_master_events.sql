-- data_activation.api_master_events definition

CREATE TABLE IF NOT EXISTS api_master_events (
   id int NOT NULL AUTO_INCREMENT,
   event_key varchar(255) DEFAULT NULL,
   event_value varchar(255) DEFAULT NULL,
   PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;