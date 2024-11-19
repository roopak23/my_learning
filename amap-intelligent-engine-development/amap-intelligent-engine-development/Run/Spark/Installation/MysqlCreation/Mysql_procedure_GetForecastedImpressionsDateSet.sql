CREATE PROCEDURE IF NOT EXISTS GetForecastedImpressionsDateSet(
    IN p_dates LONGTEXT ,
    IN p_level1 VARCHAR(255),
    IN p_level2 VARCHAR(255),
    IN p_level3 VARCHAR(255),
    IN p_level4 VARCHAR(255),
    IN p_level5 VARCHAR(255)
    
)
BEGIN
    -- Set session execution time limit
    SET SESSION MAX_EXECUTION_TIME = 30000;

    -- Temporary table to store parsed dates
    CREATE TEMPORARY TABLE IF NOT EXISTS TempDates (
        date DATETIME
    );

    -- Prepare date strings
    SET @dates = p_dates;

    -- Insert dates into the temporary table
    WHILE CHAR_LENGTH(@dates) > 0 DO
        SET @date = SUBSTRING_INDEX(@dates, ',', 1);
        INSERT INTO TempDates (date) VALUES (STR_TO_DATE(@date, '%Y-%m-%d %H:%i:%s'));
        SET @dates = SUBSTRING(@dates, CHAR_LENGTH(@date) + 2);
    END WHILE;

    -- Temporary table to store day-wise impressions
    CREATE TEMPORARY TABLE IF NOT EXISTS TempDayWiseImpressions (
        forecastedDay DATE,
        countOfRecordsIE INT,
        forecastedImpressions DECIMAL(20, 2),
        overwrittenImpressions DECIMAL(20, 2),
        percentageOfOverwriting DECIMAL(10, 2)
    );

    -- Clear the temporary table
    TRUNCATE TABLE TempDayWiseImpressions;

    -- Insert data into the temporary table
    INSERT INTO TempDayWiseImpressions (forecastedDay, countOfRecordsIE, forecastedImpressions, overwrittenImpressions, percentageOfOverwriting)
    SELECT
        DATE(ai.date) AS forecastedDay,
        COUNT(1) AS countOfRecordsIE,
        SUM(ai.future_capacity) AS forecastedImpressions,
        SUM(ai.overwritten_impressions) AS overwrittenImpressions,
        SUM(ai.percentage_of_overwriting) AS percentageOfOverwriting
    FROM api_inventorycheck ai
    JOIN STG_SA_Ad_Slot s
        ON s.adserver_adslot_id = ai.adserver_adslot_id
    WHERE ai.date IN (SELECT date FROM TempDates)
      AND s.status = 'ACTIVE'
      AND (p_level1 IS NULL OR s.Level1 = p_level1)
      AND (p_level2 IS NULL OR s.Level2 = p_level2)
      AND (p_level3 IS NULL OR s.Level3 = p_level3)
      AND (p_level4 IS NULL OR s.Level4 = p_level4)
      AND (p_level5 IS NULL OR s.Level5 = p_level5)
    GROUP BY forecastedDay;

    -- Temporary table to store total impressions
    CREATE TEMPORARY TABLE IF NOT EXISTS TempTotalImpressions (
        total_forecasted_impressions DECIMAL(20, 2),
        total_overwritten_impressions DECIMAL(20, 2)
    );

    -- Clear the temporary table
    TRUNCATE TABLE TempTotalImpressions;

    -- Insert total impressions into the temporary table
    INSERT INTO TempTotalImpressions (total_forecasted_impressions, total_overwritten_impressions)
    SELECT
        SUM(forecastedImpressions) AS total_forecasted_impressions,
        SUM(overwrittenImpressions) AS total_overwritten_impressions
    FROM TempDayWiseImpressions;

    -- Select data combining day-wise and total impressions
    SELECT
        di.forecastedDay,
        di.countOfRecordsIE,
        ti.total_forecasted_impressions,
        ti.total_overwritten_impressions,
        di.forecastedImpressions,
        di.overwrittenImpressions
    FROM TempDayWiseImpressions di
    CROSS JOIN TempTotalImpressions ti
    ORDER BY di.forecastedDay;

    -- Cleanup temporary tables
    DROP TEMPORARY TABLE IF EXISTS TempDayWiseImpressions;
    DROP TEMPORARY TABLE IF EXISTS TempTotalImpressions;
    DROP TEMPORARY TABLE IF EXISTS TempDates;

    -- Reset maximum execution time to default
    SET SESSION MAX_EXECUTION_TIME = 0;
END
