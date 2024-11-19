CREATE TABLE IF NOT EXISTS `DataMart_SAR_View` (
    `date` varchar(255),
    `site` varchar(255),
    `pageviews` INT,
    `unique_pageviews` INT,
    `content_type` varchar(255),
    `partition_date` INT,
    primary key(date,site)
);


