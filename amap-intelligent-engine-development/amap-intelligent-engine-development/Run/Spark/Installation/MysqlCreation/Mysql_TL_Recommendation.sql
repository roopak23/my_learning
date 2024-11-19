CREATE TABLE IF NOT EXISTS tl_recommendation (
  tech_line_id varchar(150) NOT NULL,
  status varchar(255) DEFAULT NULL,
  remote_id varchar(100) DEFAULT NULL,
  recommendation_id varchar(255) NOT NULL,
  recommendation_type varchar(255) DEFAULT NULL,
  recommendation_value json DEFAULT NULL,
  customer_id varchar(255) DEFAULT NULL,
  original_value varchar(255) DEFAULT NULL,
  recommendation_impact DOUBLE DEFAULT NULL,
 PRIMARY KEY (`tech_line_id`,`recommendation_id`)
);