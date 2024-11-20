CREATE TABLE IF NOT EXISTS trf_percentage_vs_all (
  adserver_id varchar(255) NOT NULL,
  adserver_adslot_id varchar(255) NOT NULL,
  adserver_target_remote_id varchar(255) NOT NULL,
  adserver_target_name varchar(255) NOT NULL,
  ratio DOUBLE,
  PRIMARY KEY (adserver_id,adserver_adslot_id,adserver_target_remote_id)
);
