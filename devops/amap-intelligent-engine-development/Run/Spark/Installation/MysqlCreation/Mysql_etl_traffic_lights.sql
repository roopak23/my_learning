CREATE TABLE IF NOT EXISTS etl_traffic_lights (
  component_name varchar(50) NOT NULL,
  process_date int NOT NULL,
  state varchar(20) DEFAULT NULL,
  create_datetime datetime DEFAULT NULL,
  modified_datetime datetime DEFAULT NULL,
  run_id varchar(225) NOT NULL,
  primary key(component_name, run_id)
);