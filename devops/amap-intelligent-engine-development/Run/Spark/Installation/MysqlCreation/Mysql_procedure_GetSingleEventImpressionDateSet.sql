CREATE PROCEDURE IF NOT EXISTS `data_activation`.`GetSingleEventImpressionDateSet`(
    IN p_eventType VARCHAR(255),    
    IN p_dates DATE                
)
BEGIN
    SET SESSION MAX_EXECUTION_TIME = 30000;
    SELECT
        ai.date AS forecastedDay,
		SUM(ai.future_capacity) AS total_forecasted_impressions,
		SUM(ai.overwritten_impressions) AS total_overwritten_impressions,	        
        SUM(ai.future_capacity) AS forecastedImpressions,
        SUM(ai.overwritten_impressions) AS overwrittenImpression,
        COUNT(1) AS countIERow
    FROM api_inventorycheck ai
    WHERE ai.event = p_eventType
      AND ai.date = p_dates
    GROUP BY ai.date
    ORDER BY ai.date;
    SET SESSION MAX_EXECUTION_TIME = 0;
END;