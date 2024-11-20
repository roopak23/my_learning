-- data_activation.adslot_hierarchy definition

CREATE TABLE IF NOT EXISTS adslot_hierarchy (
   id varchar(255) NOT NULL,
   adserver_id varchar(255) DEFAULT NULL,
   adserver_adslot_id varchar(255) DEFAULT NULL,
   adserver_adslot_parent_id varchar(255) DEFAULT NULL,
   adslot_id varchar(255) DEFAULT NULL,
   adslot_parent_id varchar(255) DEFAULT NULL,
   adserver_adslot_level INT,
   PRIMARY KEY (id),
   UNIQUE KEY adslot_hierarchy_UN (adserver_adslot_id,adserver_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;