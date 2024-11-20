-- monitoring.sa_pushstatus definition

CREATE TABLE `sa_pushstatus` (
  `object_name` varchar(150) NOT NULL,
  `number_of_recs_failed` int DEFAULT '0',
  `number_of_recs_processed` int DEFAULT '0',
  `parent_process_group_name` varchar(255) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `rundate` int NOT NULL ,
  PRIMARY KEY (`rundate`,`object_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;