CREATE PROCEDURE IF NOT EXISTS `data_activation`.`GetEventImpressionDateRange`(
    IN event VARCHAR(255),
    IN startDate DATETIME,
    IN endDate DATETIME
)
BEGIN

    SELECT
        COUNT(*) AS countOfRecordsIE,
        SUM(ai.future_capacity) AS forecastedImpressions,
        SUM(ai.overwritten_impressions) AS overwrittenImpressions
    FROM api_inventorycheck ai
    WHERE ai.event = event
      AND ai.date >= startDate
      AND ai.date <= endDate;

END;