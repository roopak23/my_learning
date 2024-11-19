-- data_activation.SO_Input_Priority definition

CREATE TABLE if not exists `so_input_priority` (
  `simulation_id` varchar(255) ,
  `media_type` varchar(255) ,
  `media_priority` Int DEFAULT NULL,
  `media_perc` Double DEFAULT NULL,
  primary key(simulation_id,media_type)
) ;
