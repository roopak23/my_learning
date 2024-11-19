CREATE TABLE if not exists api_reserved_history (
  date datetime NOT NULL,
  market_order_line_details_name varchar(255) DEFAULT NULL,
  market_order_line_details_id varchar(50) NOT NULL,
  tech_line_id varchar(255) DEFAULT NULL,
  tech_line_name varchar(255) DEFAULT NULL,
  tech_line_remote_id varchar(255) DEFAULT NULL,
  start_date datetime DEFAULT NULL,
  end_date datetime DEFAULT NULL,
  status varchar(255) DEFAULT NULL,
  media_type varchar(255) DEFAULT NULL,
  commercial_audience varchar(255) DEFAULT NULL,
  quantity int DEFAULT 0,
  quantity_reserved int DEFAULT 0,
  quantity_booked int DEFAULT 0,
  unit_type varchar(255) DEFAULT NULL,
  unit_price double DEFAULT 0.0,
  unit_net_price double DEFAULT 0.0,
  total_price double DEFAULT 0.0,
  adserver_adslot_name varchar(255) DEFAULT NULL,
  adserver_id varchar(50) DEFAULT NULL,
  adserver_adslot_id varchar(50) NOT NULL,
  length int DEFAULT 0,
  format_id varchar(255) DEFAULT NULL,
  price_item varchar(255) DEFAULT NULL,
  breadcrumb varchar(255) DEFAULT NULL,
  advertiser_id varchar(255) DEFAULT NULL,
  brand_name varchar(255) DEFAULT NULL,
  brand_id varchar(255) DEFAULT NULL,
  market_order_id varchar(255) DEFAULT NULL,
  market_order_name varchar(255) DEFAULT NULL,
  frequency_cap int DEFAULT 0,
  day_part varchar(1000) DEFAULT NULL,
  priority varchar(255) DEFAULT NULL,
  ad_format_id varchar(255) DEFAULT NULL,
  objective varchar(255) DEFAULT NULL,
  discount double DEFAULT '0',
  market_product_type_id varchar(100) DEFAULT NULL,
  calc_type varchar(255) DEFAULT NULL,
  video_duration int DEFAULT NULL,
  audience_name varchar(150) DEFAULT NULL,
  state varchar(150) DEFAULT NULL,
  city varchar(150) DEFAULT NULL,
  event varchar(150) DEFAULT NULL,
  pod_position varchar(50) DEFAULT NULL,
  video_position varchar(100) DEFAULT NULL,
  CONSTRAINT api_reserved_history_u1 UNIQUE (market_order_line_details_id,adserver_adslot_id,date,state, city, event, pod_position, video_position,adserver_id)
);


 
