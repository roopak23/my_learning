CREATE  PROCEDURE IF NOT EXISTS `data_activation`.`GetEventImpressionDateSet`(

   IN p_eventType VARCHAR(255),

   IN p_dates LONGTEXT

)
BEGIN

   SET SESSION MAX_EXECUTION_TIME = 30000;

   -- Prepare a derived table for parsed dates

   WITH ParsedDates AS (

       SELECT STR_TO_DATE(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p_dates, ',', numbers.n), ',', -1)), '%Y-%m-%d %H:%i:%s') AS date

       FROM (

           SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5

           UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10

           UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15

           UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20

       ) AS numbers

       WHERE CHAR_LENGTH(p_dates) - CHAR_LENGTH(REPLACE(p_dates, ',', '')) >= numbers.n - 1

   ),

   DayWiseImpressions AS (

       SELECT

           ai.date AS forecastedDay,

           COUNT(*) AS countOfRecordsIE,

           SUM(ai.future_capacity) AS forecastedImpressions,

           SUM(ai.overwritten_impressions) AS overwrittenImpressions,

           SUM(ai.percentage_of_overwriting) AS percentageOfOverwriting

       FROM api_inventorycheck ai

       INNER JOIN ParsedDates pd ON ai.date = pd.date

       WHERE ai.event = p_eventType

       GROUP BY ai.date

   )

   SELECT

       dwi.forecastedDay,

       SUM(dwi.forecastedImpressions) OVER () AS total_forecasted_impressions,

       SUM(dwi.overwrittenImpressions) OVER () AS total_overwritten_impressions,

       dwi.forecastedImpressions,

       dwi.overwrittenImpressions,

       dwi.countOfRecordsIE

   FROM DayWiseImpressions dwi

   ORDER BY dwi.forecastedDay;

   SET SESSION MAX_EXECUTION_TIME = 0;

END;