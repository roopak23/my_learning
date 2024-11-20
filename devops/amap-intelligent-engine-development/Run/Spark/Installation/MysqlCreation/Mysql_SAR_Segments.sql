CREATE TABLE IF NOT EXISTS `DataMart_SAR_Segments` (
    `date` varchar(255),
    `dmp_segmentid` varchar(255),
    `segment_name` varchar(100),
    `population` INT,
    `pageviews` INT,
    `category` varchar(50),
    `sub_category` varchar(50),
    `partition_date` INT,
    primary key(date,dmp_segmentid)
);


