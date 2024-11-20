-- monitoring.usecases_upstream definition

CREATE TABLE `usecases_upstream` (
  `usecase_name` varchar(150) NOT NULL,
  `upstream_system` varchar(255) NOT NULL,
  `inputtable_list` varchar(5000) DEFAULT NULL,
  `upstream_data_pull_connector` varchar(255) NOT NULL,
  PRIMARY KEY (`usecase_name`,`upstream_system`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;