CREATE PROCEDURE IF NOT EXISTS `data_activation`.`GetProductImpressionsDateRange`(
    IN p_startDate DATE,
    IN p_endDate DATE,
    IN p_level1 VARCHAR(255),
    IN p_level2 VARCHAR(255),
    IN p_level3 VARCHAR(255),
    IN p_level4 VARCHAR(255),
    IN p_level5 VARCHAR(255)
)
BEGIN

SELECT
        COUNT(1) AS countOfRecordsIE,
        SUM(ai.future_capacity) AS forecastedImpressions,
        SUM(ai.overwritten_impressions) AS overwrittenImpressions
    FROM api_inventorycheck ai
    JOIN STG_SA_Ad_Slot s ON s.adserver_adslot_id = ai.adserver_adslot_id
    WHERE ai.date >= p_startDate
      AND ai.date <= p_endDate
      AND s.status = 'ACTIVE'
      AND (p_level1 IS NULL OR s.Level1 = p_level1)
      AND (p_level2 IS NULL OR s.Level2 = p_level2)
      AND (p_level3 IS NULL OR s.Level3 = p_level3)
      AND (p_level4 IS NULL OR s.Level4 = p_level4)
      AND (p_level5 IS NULL OR s.Level5 = p_level5);
 
   
END;