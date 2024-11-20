 CREATE TABLE IF NOT EXISTS `AUD_user_segment_population` (
    `date` varchar(255) DEFAULT NULL,
    `segment_id` int(11) DEFAULT NULL,
    `population` int(11) DEFAULT NULL
 ) ENGINE=InnoDB DEFAULT CHARSET=latin1;