CREATE TABLE IF NOT EXISTS to_recommendation (
  tech_order_id varchar(150) NOT NULL,
  status varchar(255) DEFAULT NULL,
  remote_id varchar(100) DEFAULT NULL,
  recommendation_id varchar(255) NOT NULL,
  recommendation_type varchar(255) DEFAULT NULL,
  recommendation_value json DEFAULT NULL,
  customer_id varchar(255) DEFAULT NULL,
 PRIMARY KEY (`tech_order_id`,`recommendation_id`)
);