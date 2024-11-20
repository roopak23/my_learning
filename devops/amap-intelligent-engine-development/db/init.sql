

-- NIFI
CREATE USER 'nifi'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON data_activation . * TO 'nifi'@'%';
CREATE SCHEMA data_activation;
-- KEYCLOAK (pre migration)
CREATE USER 'keycloak'@'%' IDENTIFIED BY 'password';
CREATE DATABASE keycloak CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
GRANT ALL PRIVILEGES ON keycloak . * TO 'keycloak'@'%';

-- KEYCLOAK (post migration)
CREATE USER 'keycloakx'@'%' IDENTIFIED BY 'password';
CREATE DATABASE keycloakx CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
GRANT ALL PRIVILEGES ON keycloakx . * TO 'keycloakx'@'%';


-- AIRFLOW
CREATE DATABASE airflow CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE USER 'airflow'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON airflow . * TO 'airflow'@'%';

-- API LAYER
CREATE USER 'api'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON data_activation . * TO 'api'@'%';
CREATE SCHEMA data_activation;

-- EMR HIVE
CREATE USER 'hive_user'@'%' IDENTIFIED BY 'password';
CREATE DATABASE hive_metastore CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
GRANT ALL PRIVILEGES ON hive_metastore . * TO 'hive_user'@'%';

-- EMR my_mysql
CREATE USER 'db_admin'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON data_activation . * TO 'db_admin'@'%';
GRANT ALL PRIVILEGES ON segmentation . * TO 'db_admin'@'%';

CREATE USER 'dm_admin'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON data_activation . * TO 'dm_admin'@'%';
GRANT ALL PRIVILEGES ON segmentation . * TO 'dm_admin'@'%';


-- ETL monitoting lambda
CREATE USER 'monitoring'@'%' IDENTIFIED BY 'password';
CREATE DATABASE monitoring CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
GRANT ALL PRIVILEGES ON monitoring . * TO 'monitoring'@'%';
GRANT SELECT ON airflow . * TO 'monitoring'@'%';
GRANT SELECT on data_activation.* to 'monitoring'@'%'

--- # This table should be created if segmantaion tool is not enabled
-- data_activation.trf_segments definition . Table will not be used but it's required for the API update

CREATE TABLE data_activation.trf_segments (
  `segment_id` varchar(255) DEFAULT NULL,
  `segment_name` varchar(255) DEFAULT NULL,
  `technical_remote_id` varchar(255) DEFAULT NULL,
  `technical_remote_name` varchar(255) DEFAULT NULL,
  `adserver_id` varchar(255) DEFAULT NULL,
  `ratio_population` varchar(255) DEFAULT NULL
);


