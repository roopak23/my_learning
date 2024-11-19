CREATE PROCEDURE IF NOT EXISTS GetTestData (
)
BEGIN
    SELECT
        adserver_adslot_id FROM api_inventorycheck LIMIT 10;
END ;
COMMIT ;