CREATE TABLE if not exists trf_adunitsegmentusage (
  adserver_adslot_id varchar(150) NOT NULL,
  adserver_adslot_name varchar(255) DEFAULT NULL,
  adserver_id varchar(100) NOT NULL,
  sitepage varchar(255) NOT NULL,
  adserver_target_remote_id varchar(255) NOT NULL,
  adserver_target_name varchar(255) DEFAULT NULL,
  adserver_target_type varchar(255) DEFAULT NULL,
  adserver_target_category varchar(255) DEFAULT NULL,
  adserver_target_code varchar(255) DEFAULT NULL,
  PRIMARY KEY (adserver_adslot_id,adserver_id,sitepage,adserver_target_remote_id)
);