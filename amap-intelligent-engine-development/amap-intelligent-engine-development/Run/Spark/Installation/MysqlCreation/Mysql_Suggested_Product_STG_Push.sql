CREATE TABLE IF NOT EXISTS `Suggested_Product_STG_Push` (
 dm_id varchar(255)  NOT NULL,
 proposal_dm_id  varchar(255)  NOT NULL,
 create_datetime  DATETIME NOT NULL,
 update_datetime  DATETIME NOT NULL,
PRIMARY KEY (dm_id)
);

