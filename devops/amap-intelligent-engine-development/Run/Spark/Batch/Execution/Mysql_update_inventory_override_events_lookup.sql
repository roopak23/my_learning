TRUNCATE data_activation.inventory_override_events_lookup;
INSERT INTO data_activation.inventory_override_events_lookup
(event)
SELECT event FROM 
(
SELECT DISTINCT(event) as event FROM api_inventorycheck  WHERE
api_inventorycheck.event is NOT NULL and api_inventorycheck.event != '' and api_inventorycheck.event != 'NA'
)TB;
