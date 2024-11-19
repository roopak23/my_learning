-- data_activation.SO_Input_Overall definition

CREATE TABLE if not exists `so_input_overall` (
  `simulation_id` varchar(255) ,
  `simulation_name` varchar(255) DEFAULT NULL,
  `simulation_date` date DEFAULT NULL,
  `status` varchar(100) DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `update_date` date DEFAULT NULL,
  `update_by` varchar(255) DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `revenue_max` int(11) DEFAULT NULL,
  `inventory_saturation` int(11) DEFAULT NULL,
  `partition_date` int(11) DEFAULT NULL,
  PRIMARY KEY (`simulation_id`)
)