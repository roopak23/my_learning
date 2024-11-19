-- monitoring.usecases_downstream definition

CREATE TABLE `usecases_downstream` (
  `usecase_name` varchar(150) NOT NULL,
  `downstream_system` varchar(255) NOT NULL,
  `dmoutputtable_list` varchar(5000) DEFAULT NULL,
  `downstreamtable_list` varchar(5000) NOT NULL,
  `description` varchar(255) NOT NULL,
  PRIMARY KEY (`usecase_name`,`downstream_system`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;