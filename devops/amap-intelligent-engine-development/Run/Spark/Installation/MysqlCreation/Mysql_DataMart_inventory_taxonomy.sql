-- data_activation.DataMart_inventory_taxonomy definition

CREATE TABLE IF NOT EXISTS DataMart_inventory_taxonomy (
  segment_name VARCHAR(255),
  catalog_item_id VARCHAR(255),
  gender VARCHAR(255) DEFAULT NULL,
  age VARCHAR(255) DEFAULT NULL,
  interest VARCHAR(255) DEFAULT NULL
);