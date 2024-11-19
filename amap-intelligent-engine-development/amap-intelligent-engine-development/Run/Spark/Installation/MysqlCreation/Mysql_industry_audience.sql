CREATE TABLE IF NOT EXISTS `industry_audience` (
    `industry` varchar(255) NOT NULL,
    `audience_id` varchar(255) NOT NULL,
    `audience_name` varchar(255),
    `audience_frequency` INTEGER ,
    primary key(industry,audience_id)
);


