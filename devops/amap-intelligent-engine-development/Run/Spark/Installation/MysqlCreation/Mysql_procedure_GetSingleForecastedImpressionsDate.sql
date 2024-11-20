CREATE PROCEDURE IF NOT EXISTS `data_activation`.`GetSingleForecastedImpressionsDate`(
    IN p_dates LONGTEXT ,
    IN p_level1 VARCHAR(255),
    IN p_level2 VARCHAR(255),
    IN p_level3 VARCHAR(255),
    IN p_level4 VARCHAR(255),
    IN p_level5 VARCHAR(255)
)
BEGIN
    SET SESSION MAX_EXECUTION_TIME = 30000;
    SELECT
    DATE(ai.date) AS forecastedDay,
        COUNT(1) AS countOfRecordsIE,
        SUM(ai.future_capacity) AS total_forecasted_impressions,
        SUM(ai.overwritten_impressions) AS total_overwritten_impressions,
        SUM(ai.future_capacity) AS forecastedImpressions,
        SUM(ai.overwritten_impressions) AS overwrittenImpressions
    FROM api_inventorycheck ai
    JOIN STG_SA_Ad_Slot s ON s.adserver_adslot_id = ai.adserver_adslot_id
    WHERE ai.date = DATE(p_dates)
      AND s.status = 'ACTIVE'
      AND (p_level1 IS NULL OR s.Level1 = p_level1)
          AND (p_level2 IS NULL OR s.Level2 = p_level2)
          AND (p_level3 IS NULL OR s.Level3 = p_level3)
          AND (p_level4 IS NULL OR s.Level4 = p_level4)
          AND (p_level5 IS NULL OR s.Level5 = p_level5)
      GROUP BY forecastedDay;
    SET SESSION MAX_EXECUTION_TIME = 0;
   
END;