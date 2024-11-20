CREATE TABLE IF NOT EXISTS TRF_Advertiser (
    advertiser_id varchar(255),
    advertiser_name varchar(255),
    record_type varchar(255),
    industry varchar(255),
    brand_name varchar(255),
    brand_id varchar(255),
    adserver_id varchar(255),
    primary key(advertiser_id, brand_id, adserver_id)
);